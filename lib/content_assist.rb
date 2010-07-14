require 'content_assist/index'
require 'content_assist/offset_node_locator'
require 'content_assist/closest_spanning_node_locator'
require 'content_assist/scoped_node_locator'

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
    # "capitalize!" => ["String", "NilClass"]
    "ceil" => "Fixnum",
    "center" => "String",
    "chomp" => "String",
    # "chomp!" => ["String", "NilClass"]
    "chop" => "String",
    # "chop!" => ["String", "NilClass"]
    "concat" => "String",
    "count" => "Fixnum",
    "crypt" => "String",
    "downcase" => "String",
    # "downcase!" => ["String", "NilClass"]
    "dump" => "String",
    "floor" => "Fixnum",
    # "gets" => ["String", "NilClass"],
    "gsub" => "String",
    # "gsub!" => ["String", "NilClass"]
    "hash" => "Fixnum",
    "index" => "Fixnum",
    "inspect" => "String",
    "intern" => "Symbol",
    "length" => "Fixnum",
    "now" => "Time",
    "round" => "Fixnum",
    "size" => "Fixnum",
    # "slice" => ["String", "Array", "NilClass", "Object", "Fixnum"],
    # "slice!" => ["String", "Array", "NilClass", "Object", "Fixnum"],
    "strip" => "String",
    # "strip!" => ["String", "NilClass"]
    "sub" => "String",
    # "sub!" => ["String", "NilClass"]
    "swapcase" => "String",
    # "swapcase!" => ["String", "NilClass"]
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
    return [] if root_node.nil?    
    
    # Now try and get the node that matches our offset!      
    node_at_offset = OffsetNodeLocator.new.find(root_node, offset)
    
    case node_at_offset.node_type
    when org.jrubyparser.ast.NodeType::CALLNODE # Method call, infer type of receiver, then suggest methods on type
      suggest_methods(infer(node_at_offset.getReceiverNode), prefix)
      # TODO If we were unable to infer type (beyond "Object"), then we should do a global method name search for any methods with same prefix
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
      # Suggest global vars with matching prefix
      suggestions = []
      all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
        results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::GLOBAL_DECL],
          prefix, com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
        results.each {|r| suggestions << r.word } unless results.nil?
      end  
      suggestions.uniq.sort.map {|proposal| create_proposal(proposal, prefix, GLOBAL_VAR_IMAGE) }
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
      # FIXME For debug purposes we currently spit out node type when it doesn't match our current categories...
      [node_at_offset.node_type.to_s]
    end
  end
  
  private
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
    @prefix = @src[0...offset]
    
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
    begin
      # Sneaky haxor! Try and see if this is a type we can grab in our JRuby runtime and inspect!
      # FIXME Should really be using the user's indices and runtime to determine the methods, but this is a nice workable shortcut for now
      methods = eval(type_name).public_instance_methods(true)
      methods = methods.sort.select {|m| m.start_with? prefix }
      methods.map {|m| create_proposal(m, prefix, PUBLIC_METHOD_IMAGE)}
    rescue
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
  
  # Returns the name of a Type (string) that we have deemed as the inferred type to try
  def infer(node)
    return nil if node.nil?
  
    # If the node is a literal, grab it's type
    type = case node.node_type
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
      node.name # Assume if a receiver is a constant, that it's a type name # FIXME Actually check by searching for a type/constant with that name...
    when org.jrubyparser.ast.NodeType::CALLNODE
      return COMMON_METHODS[node.name] if COMMON_METHODS.has_key? node.name # FIXME Allow us to cheat on "query?" methods to return TrueClass/FalseClass
      # FIXME Recursive inference on this method's receiver is probably not the right thing to do here. We should try and determine the method return type
      # Should return receiver as type when method is "new", or receiver is a constant that we can resolve to a type in our index
      infer(root_node, node.getReceiverNode)
    when org.jrubyparser.ast.NodeType::FCALLNODE, org.jrubyparser.ast.NodeType::VCALLNODE
      return COMMON_METHODS[node.name] if COMMON_METHODS.has_key? node.name # FIXME Allow us to cheat on "query?" methods to return TrueClass/FalseClass
      # Implicit self is the receiver, so traverse AST to determine the enclosing type's name
      get_self(root_node, node.position.start_offset)
    else
      # TODO When its a variable, we need to trace back it's assignments using dataflow analysis!
      "Object"
    end
  end
end