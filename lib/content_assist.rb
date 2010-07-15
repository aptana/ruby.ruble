require 'content_assist/index'
require 'content_assist/offset_node_locator'
require 'content_assist/closest_spanning_node_locator'
require 'content_assist/scoped_node_locator'
require 'content_assist/first_precursor_node_locator'

# Ruby Content Assistant
class ContentAssistant
  
  # ID of the ruby plugin that we're reusing icons from
  RUBY_PLUGIN_ID = "com.aptana.editor.ruby"
  
  # Images used
  LOCAL_VAR_IMAGE = "icons/local_var_obj.gif"
  CLASS_VAR_IMAGE = "icons/class_var_obj.gif"
  GLOBAL_VAR_IMAGE = "icons/global_obj.png"
  CLASS_IMAGE = "icons/class_obj.png"
  CONSTANT_IMAGE = "icons/constant_obj.gif"
  MODULE_IMAGE = "icons/module_obj.png"
  INSTANCE_VAR_IMAGE = "icons/instance_var_obj.gif"
  PUBLIC_METHOD_IMAGE = "icons/method_public_obj.png"
  
  # A simple way to "cheat" on type inference. If we hit one of these common method calls, we assume a fixed return type
  COMMON_METHODS = {
    "capitalize" => "String",
    "capitalize!" => ["String", "NilClass"],
    "ceil" => "Fixnum",
    "center" => "String",
    "chomp" => "String",
    "chomp!" => ["String", "NilClass"],
    "chop" => "String",
    "chop!" => ["String", "NilClass"],
    "concat" => "String",
    "count" => "Fixnum",
    "crypt" => "String",
    "downcase" => "String",
    "downcase!" => ["String", "NilClass"],
    "dump" => "String",
    "floor" => "Fixnum",
    "gets" => ["String", "NilClass"],
    "gsub" => "String",
    "gsub!" => ["String", "NilClass"],
    "hash" => "Fixnum",
    "index" => "Fixnum",
    "inspect" => "String",
    "intern" => "Symbol",
    "length" => "Fixnum",
    "now" => "Time",
    "round" => "Fixnum",
    "size" => "Fixnum",
    "slice" => ["String", "Array", "NilClass", "Object", "Fixnum"],
    "slice!" => ["String", "Array", "NilClass", "Object", "Fixnum"],
    "strip" => "String",
    "strip!" => ["String", "NilClass"],
    "sub" => "String",
    "sub!" => ["String", "NilClass"],
    "swapcase" => "String",
    "swapcase!" => ["String", "NilClass"],
    "to_a" => "Array",
    "to_ary" => "Array",
    "to_i" => "Fixnum",
    "to_int" => "Fixnum",
    "to_f" => "Float",
    "to_proc" => "Proc",
    "to_s" => "String",
    "to_str" => "String",
    "to_string" => "String",
    "to_sym" => "Symbol",
    "unpack" => "Array"
  }
  
  def initialize(io, caret_offset)
    @io = io
    @offset = caret_offset - 1 # Move back one char...
  end
  
  # Returns an array of code assists proposals for a given caret offset in the source
  def assist
    Ruble::Logger.log_level = :trace
    return [] if root_node.nil?    
    
    # Now try and get the node that matches our offset!      
    node_at_offset = OffsetNodeLocator.new.find(root_node, offset)
    
    case node_at_offset.node_type
    when org.jrubyparser.ast.NodeType::CALLNODE # Method call, infer type of receiver, then suggest methods on type
      types = infer(node_at_offset.getReceiverNode)
      # TODO If we were unable to infer type (beyond "Object"), then we should do a global method name search for any methods with same prefix
      if types.respond_to? :each
        suggestions = []
        types.each {|t| suggestions << suggest_methods(t, prefix) }
        # FIXME Sort and limit to uniques!
        suggestions.flatten
      else
        suggest_methods(types, prefix)
      end      
    when org.jrubyparser.ast.NodeType::FCALLNODE, org.jrubyparser.ast.NodeType::VCALLNODE # Implicit self
      # Infer type of 'self', suggest methods on that type matching the prefix
      suggestions = suggest_methods(get_self(offset), prefix)
      # VCall could also be an attempt to refer to a local/dynamic var that is incomplete
      if node_at_offset.node_type == org.jrubyparser.ast.NodeType::VCALLNODE
        # Find innermost method scope and suggest local vars in scope!
        method_node = ClosestSpanningNodeLocator.new.find(root_node, offset) {|node| node.node_type == org.jrubyparser.ast.NodeType::DEFNNODE }
        method_node.scope.getVariables.each {|v| suggestions << create_proposal(v, prefix, LOCAL_VAR_IMAGE) } unless method_node.nil?
      end
      suggestions
    when org.jrubyparser.ast.NodeType::INSTVARNODE, org.jrubyparser.ast.NodeType::INSTASGNNODE, org.jrubyparser.ast.NodeType::CLASSVARNODE, org.jrubyparser.ast.NodeType::CLASSVARASGNNODE
      # Suggest instance/class vars with matching prefix in file/enclosing type
      suggestions = []      
      # Find enclosing type and suggest instance/class vars defined within that type's scope!
      type_node = enclosing_type(offset)
      variables = ScopedNodeLocator.new.find(type_node) {|node| node.node_type == org.jrubyparser.ast.NodeType::INSTASGNNODE || node.node_type == org.jrubyparser.ast.NodeType::CLASSVARASGNNODE || node.node_type == org.jrubyparser.ast.NodeType::CLASSVARDECLNODE }
      variables.each {|v| suggestions << v.name if v.name.start_with? prefix } unless variables.nil?
      suggestions.uniq.sort.map {|proposal| create_proposal(proposal, prefix, proposal.start_with?("@@") ? CLASS_VAR_IMAGE : INSTANCE_VAR_IMAGE) }
    when org.jrubyparser.ast.NodeType::GLOBALVARNODE, org.jrubyparser.ast.NodeType::GLOBALASGNNODE
      suggest_globals(node_at_offset)
    when org.jrubyparser.ast.NodeType::COLON2NODE, org.jrubyparser.ast.NodeType::COLON3NODE, org.jrubyparser.ast.NodeType::CONSTNODE
      # Suggest all types with matching prefix
      suggestions = []
      all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
        results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::TYPE_DECL],
          prefix, com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
        results.each {|r| suggestions << create_proposal(r.word.split('/').first, prefix, r.word.split('/').last == "M" ? MODULE_IMAGE : CLASS_IMAGE) } unless results.nil?
      end
      # TODO Use the AST to grab constants in file/scope
      # Now add constants in project
      results = index(ENV['TM_FILEPATH']).query([com.aptana.editor.ruby.index.IRubyIndexConstants::CONSTANT_DECL],
          prefix, com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
      results.each {|r| suggestions << create_proposal(r.word, prefix, CONSTANT_IMAGE) } unless results.nil?
      suggestions
    else
      # A node type we currently don't handle
      Ruble::Logger.trace node_at_offset.node_type
      []
    end
  end
  
  private
  # Suggest global vars with matching prefix
  def suggest_globals
    suggestions = []
    all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
      results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::GLOBAL_DECL],
        prefix, com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
      results.each {|r| suggestions << r.word } unless results.nil?
    end  
    suggestions.uniq.sort.map {|proposal| create_proposal(proposal, prefix, GLOBAL_VAR_IMAGE) }
  end
  
  def offset
    @offset
  end
  
  def parser_config
    org.jrubyparser.parser.ParserConfiguration.new(0, org.jrubyparser.CompatVersion::RUBY1_8)
  end
  
  # Lazily parse the source
  def root_node
    return @root_node unless @root_node.nil?
    
    @src = @io.read
    @root_node = org.jrubyparser.Parser.new.parse(ENV['TM_FILENAME'], java.io.StringReader.new(@src), parser_config) rescue nil
    if @root_node.nil?
      # if the syntax is broken because we're mid-edit try to fix common cases of "@|", "$|" or "something.|"
      char = @src[offset, 1]
      case char
      when ".", ":", "@", "$"
        modified_src = @src
        modified_src[offset] = char + "a"
        @root_node = org.jrubyparser.Parser.new.parse(ENV['TM_FILENAME'], java.io.StringReader.new(modified_src), parser_config) rescue nil
      end
    end
    @root_node
  end
  
  # Generate a hash representing a proposal with an optional image path
  def create_proposal(proposal, prefix, image = nil, location = nil)
   hash = { :insert => proposal[prefix.length..-1], :display => proposal }
   hash[:image] = image_url(RUBY_PLUGIN_ID, image).toString unless image.nil?
   hash[:location] = location unless location.nil?
   hash
  end
  
  # Return an URL that can be used to refer to an image packaged in a plugin
  def image_url(plugin_id, path)
    org.eclipse.core.runtime.FileLocator.find(org.eclipse.core.runtime.Platform.getBundle(plugin_id), org.eclipse.core.runtime.Path.new(path), nil)
  end
  
  # Read backwards from our offset in the src until we hit a space, period or colon
  def prefix
    return @prefix if @prefix
    @prefix = @src[0...offset + 1]

    # find last period/space/:
    index = @prefix.rindex('.')
    @prefix = @prefix[(index + 1)..-1] if !index.nil?

    index = @prefix.rindex(':')
    @prefix = @prefix[(index + 1)..-1] if !index.nil?

    index = @prefix.rindex(' ')
    @prefix = @prefix[(index + 1)..-1] if !index.nil?

    return @prefix
  end
  
  # Returns the innermost wrapping type's name
  def get_self(offset)
    enclosing_type(offset).getCPath.name
  end
  
  # Given the root node of the AST and an offset, traverse to find the innermost enclosing type at the offset
  def enclosing_type(offset)
    ClosestSpanningNodeLocator.new.find(root_node, offset) {|node| node.node_type == org.jrubyparser.ast.NodeType::CLASSNODE or node.node_type == org.jrubyparser.ast.NodeType::MODULENODE }
  end
  
  # Given a type name, we try to reconstruct the type to get at it's methods. Then we generate proposals from that listing
  def suggest_methods(type_name, prefix)
    Ruble::Logger.trace "Suggesting methods for: #{type_name} with prefix: #{prefix}"
    begin
      # Sneaky haxor! Try and see if this is a type we can grab in our JRuby runtime and inspect!
      # FIXME Should really be using the user's indices and runtime to determine the methods, but this is a nice workable shortcut for now
      methods = eval(type_name).public_instance_methods(true)
      methods = methods.sort.select {|m| m.start_with? prefix }
      Ruble::Logger.trace "Instantiated in JRuby, grabbed methods: #{methods}"
      methods.map {|m| create_proposal(m, prefix, PUBLIC_METHOD_IMAGE)}
    rescue
      Ruble::Logger.trace "Instantiation in JRuby failed, constructing type from indices"
      # Damn, we have to do things the hard way!
      proposals = []
      
      # Find all declarations of types with this exact name, and hold onto the filename for each occurence
      docs = []
      all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
        results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::TYPE_DECL], type_name + "/", com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
        results.each {|r| r.getDocuments.each {|d| docs << d } } unless results.nil?
      end
      docs.flatten
      # Now iterate over files containing a type with this name...
      docs.each do |doc|
        doc = doc[5..-1] if doc.start_with? "file:" # Need to convert doc from a URI to a filepath
        
        # Parse the file into an AST...
        begin
          # If this is pointing to currently edited file, use our pre-parsed AST so we pick up changes since last save
          ast = (doc == ENV['TM_FILEPATH'] ? root_node : org.jrubyparser.Parser.new.parse(doc, java.io.FileReader.new(doc), parser_config))

          # Traverse the AST into an in-memory model...
          script = com.aptana.editor.ruby.parsing.ast.RubyScript.new(0, -1)
          builder = com.aptana.editor.ruby.parsing.RubyStructureBuilder.new(script)
          com.aptana.editor.ruby.parsing.SourceElementVisitor.new(builder).acceptNode(ast)
          
          # Now grab the matching type(s) from the model...
          types = script.getChildrenOfType(com.aptana.editor.ruby.core.IRubyElement::TYPE) # FIXME This assumes the type is a direct child of the toplevel in this script, which won't be right a lot of the time!
          types = types.select {|t| t.name == type_name }
          types.each do |t|
            # Now we grab that type's methods
            t.getMethods.each do |m|
              # FIXME Use the correct image given the visibility!
              proposals << create_proposal(m.name, prefix, PUBLIC_METHOD_IMAGE, type_name) if m.name.start_with?(prefix) && (m.visibility == com.aptana.editor.ruby.core.IRubyMethod::Visibility::PUBLIC || doc == ENV['TM_FILEPATH'])
            end
          end
        rescue
          # couldn't parse the file
          Ruble::Logger.log_error "Couldn't parse #{doc}"
        end
      end
      proposals
    end  
  end
  
  # Returns the name of a Type (string) that we have deemed as the inferred type to try. 
  # Called when we're trying to do code assist with a method call having a receiver. This guesses the type of the receiver.
  def infer(node)
    # TODO We will probably need to do something here to avoid infinite recursion! Limit recursive depth? track nodes?
    return nil if node.nil?
    
    Ruble::Logger.trace "Inferring type of: #{node}"
  
    # If the node is a literal, grab it's type
    case node.node_type
    when org.jrubyparser.ast.NodeType::ARRAYNODE, org.jrubyparser.ast.NodeType::ZARRAYNODE
      "Array"
    when org.jrubyparser.ast.NodeType::SYMBOLNODE, org.jrubyparser.ast.NodeType::DSYMBOLNODE
      "Symbol"
    when org.jrubyparser.ast.NodeType::STRNODE, org.jrubyparser.ast.NodeType::DSTRNODE, org.jrubyparser.ast.NodeType::DXSTRNODE, org.jrubyparser.ast.NodeType::XSTRNODE
      "String"
    when org.jrubyparser.ast.NodeType::REGEXPNODE, org.jrubyparser.ast.NodeType::DREGEXPNODE
      "Regexp"
    when org.jrubyparser.ast.NodeType::TRUENODE
      "TrueClass"
    when org.jrubyparser.ast.NodeType::FALSENODE
      "FalseClass"
    when org.jrubyparser.ast.NodeType::NILNODE
      "NilClass"
    when org.jrubyparser.ast.NodeType::FIXNUMNODE
      "Fixnum"
    when org.jrubyparser.ast.NodeType::FLOATNODE
      "Float"
    when org.jrubyparser.ast.NodeType::BIGNUMNODE
      "Bignum"
    when org.jrubyparser.ast.NodeType::HASHNODE
      "Hash"
    when org.jrubyparser.ast.NodeType::CONSTNODE
      # Assume if a receiver is a constant, that it's a type name
      # FIXME Actually check by searching for a type/constant with that name... if no type exists, assume constant, so we need to infer type of it?
      node.name
    when org.jrubyparser.ast.NodeType::CALLNODE, org.jrubyparser.ast.NodeType::FCALLNODE, org.jrubyparser.ast.NodeType::VCALLNODE
      infer_return_type(node)
    when org.jrubyparser.ast.NodeType::LOCALVARNODE
      # When its a variable, we need to trace back it's assignments using dataflow analysis!
      preceding_assign = FirstPrecursorNodeLocator.new.find(root_node, node.position.start_offset - 1) {|n| n.node_type == org.jrubyparser.ast.NodeType::LOCALASGNNODE && n.name == node.name }
      return "Object" unless preceding_assign
      infer(preceding_assign.value_node)
      
    # Class and Instance vars are kind of special. Look for any assignments in type
    when org.jrubyparser.ast.NodeType::INSTVARNODE      
      assigns = ScopedNodeLocator.new.find(enclosing_type(node.position.start_offset))  {|n| n.node_type == org.jrubyparser.ast.NodeType::INSTASGNNODE && n.name == node.name }
      types = []
      assigns.each {|a| types << infer(a.value_node) }
      types.flatten
     when org.jrubyparser.ast.NodeType::CLASSVARNODE
      assigns = ScopedNodeLocator.new.find(enclosing_type(node.position.start_offset))  {|n| (n.node_type == org.jrubyparser.ast.NodeType::CLASSVARASGNNODE || n.node_type == org.jrubyparser.ast.NodeType::CLASSVARDECLNODE) && n.name == node.name }
      types = []
      assigns.each {|a| types << infer(a.value_node) }
      types.flatten
    else
      "Object"
    end
  end
  
  # Tries to infer the return type of a method
  def infer_return_type(method_node)
    # First let's cheat and return boolean for methods ending in "?"
    return ["TrueClass", "FalseClass"] if method_node.name.end_with? "?"
    # Then let's look at common method names and cheat their return types too
    return COMMON_METHODS[method_node.name] if COMMON_METHODS.has_key? method_node.name
    # Ok, we can't cheat. We need to actually try to figure out the return type!
    case method_node.node_type
    when org.jrubyparser.ast.NodeType::CALLNODE
      # Figure out the type of the receiver...
      receiver_types = infer(root_node, method_node.getReceiverNode)
      # If method name is "new" return receiver as type
      return receiver_types if method_node.name == "new"
      # TODO grab this method on the receiver type and grab the return type from it
      "Object"
    when org.jrubyparser.ast.NodeType::FCALLNODE, org.jrubyparser.ast.NodeType::VCALLNODE
      # Grab enclosing type, search it's hierarchy for this method, grab it's return type(s)
      type_node = enclosing_type(method_node.position.start_offset)
      methods = ScopedNodeLocator.new.find(type_node) {|node| node.node_type == org.jrubyparser.ast.NodeType::DEFNNODE }
      # FIXME This doesn't take hierarchy of type into account!
      methods = methods.select {|m| m.name == method_node.name } if methods
      return "Object" if methods.nil? or methods.empty?
      # Now traverse the method and gather return types
      return_nodes = ScopedNodeLocator.new.find(methods.first) {|node| node.node_type == org.jrubyparser.ast.NodeType::RETURNNODE }
      types = []
      return_nodes.each {|r| types << infer(r.value_node) } if return_nodes
      
      # Get method body as a BlockNode, grab last child, that's the implicit return.
      implicit_return = methods.first.body_node
      if implicit_return
        implicit_return = implicit_return.last if implicit_return.node_type == org.jrubyparser.ast.NodeType::BLOCKNODE
        implicit_return = implicit_return.next_node if implicit_return.node_type == org.jrubyparser.ast.NodeType::NEWLINENODE
        # TODO If it's something like an if/case, we need to recurse into the bodies with each branch's last line as the return type
        case implicit_return.node_type
        when org.jrubyparser.ast.NodeType::RETURNNODE
          # Ignore
        else
          types << infer(implicit_return)
        end
      end
      return "Object" if types.empty?
      types.flatten
    else
      # Should never end up here...
      "Object"
    end
  end
end