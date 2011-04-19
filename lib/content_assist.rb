require 'content_assist/index'
require 'content_assist/offset_node_locator'
require 'content_assist/closest_spanning_node_locator'
require 'content_assist/scoped_node_locator'
require 'content_assist/first_precursor_node_locator'

# Ruby Content Assistant
class ContentAssistant
  
  KEYWORDS = %w{alias and BEGIN begin break case class def defined do else elsif END end ensure false for if in module next nil not or redo rescue retry return self super then true undef unless until when while yield}
  # ID of the ruby plugin that we're reusing icons from
  RUBY_PLUGIN_ID = "com.aptana.editor.ruby"
  
  # Images used
  LOCAL_VAR_IMAGE = "icons/local_var_obj.png"
  CLASS_VAR_IMAGE = "icons/class_var_obj.png"
  GLOBAL_VAR_IMAGE = "icons/global_obj.png"
  CLASS_IMAGE = "icons/class_obj.png"
  CONSTANT_IMAGE = "icons/constant_obj.png"
  MODULE_IMAGE = "icons/module_obj.png"
  INSTANCE_VAR_IMAGE = "icons/instance_var_obj.png"
  PUBLIC_METHOD_IMAGE = "icons/method_public_obj.png"
  PRIVATE_METHOD_IMAGE = "icons/method_private_obj.png"
  PROTECTED_METHOD_IMAGE = "icons/method_protected_obj.png"
  
  # String representation of index separator char (so I can insert into strings and have it be right)
  INDEX_SEPARATOR = com.aptana.editor.ruby.index.IRubyIndexConstants::SEPARATOR.chr # '/'
  MODULE_SUFFIX = com.aptana.editor.ruby.index.IRubyIndexConstants::MODULE_SUFFIX.chr # "M"
  
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
    #Ruble::Logger.log_level = :trace
    Ruble::Logger.trace "Starting Code Assist"
    # If we can't parse because syntax is broken, fallback to keyword suggestions only...
    if root_node.nil?
      suggestions = []
      # TODO Are there other suggestions we can give without having the AST?
      # TODO If prefix begins with "@", search the input src with a regexp for instance variables?
      KEYWORDS.select {|k| k.start_with?(prefix) }.each {|k| suggestions << create_proposal(k, prefix) }
      return suggestions
    end
    
    # Ok, we could parse and have an AST to work off of
    # Now try and get the node that matches our offset!
    node_at_offset = OffsetNodeLocator.new.find(root_node, offset)
    if node_at_offset.nil?
      Ruble::Logger.trace "No node found at offset: #{offset}"
      # TODO Empty file, empty line? What should we suggest? Types in all indices? Globals? Pre-defined constants?
      return []
    end
    
    Ruble::Logger.trace node_at_offset.node_type # Log node type for debug purposes
    Ruble::Logger.trace "Prefix: #{prefix}"
    Ruble::Logger.trace "Full Prefix: #{full_prefix}"
    
    case node_at_offset.node_type
    when org.jrubyparser.ast.NodeType::CALLNODE # Method call, infer type of receiver, then suggest methods on type
      types = infer(node_at_offset.getReceiverNode)
      types = [types].flatten
      
      suggestions = []      
      if types.size == 1 && types.first == "Object" && prefix.length > 0
        # Only inferred to "Object", do global method prefix search
        all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
          prefix_search(index, com.aptana.editor.ruby.index.IRubyIndexConstants::METHOD_DECL) do |r|
            # TODO Include r.documents joined to a string as :location
            suggestions << create_proposal(r.word.split(INDEX_SEPARATOR).first, prefix, PUBLIC_METHOD_IMAGE)
          end
        end
      else
        # Inferred actual types!
        types.each {|t| suggestions << suggest_methods(t, prefix) }
        suggestions.flatten!
      end
      
      # If we hacked the source after a ::, we'll end up here. This means we also need to suggest constants
      if full_prefix.end_with? "::"
        suggestions << suggest_types_and_constants(full_prefix)
        suggestions.flatten!        
      end
      
      # Sort and limit method proposals to uniques
      suggestions.uniq {|p| p[:insert] }.sort_by {|p| p[:display] }
    when org.jrubyparser.ast.NodeType::FCALLNODE, org.jrubyparser.ast.NodeType::VCALLNODE # Implicit self
      suggestions = []
      # VCall could also be an attempt to refer to a local/dynamic var that is incomplete
      if node_at_offset.node_type == org.jrubyparser.ast.NodeType::VCALLNODE
        # TODO Add keywords like 'def', 'class', 'module'
        KEYWORDS.select {|k| k.start_with?(prefix) }.each {|k| suggestions << create_proposal(k, prefix) }
        # Find innermost method scope and suggest local vars in scope!
        method_node = ClosestSpanningNodeLocator.new.find(root_node, offset) {|node| node.node_type == org.jrubyparser.ast.NodeType::DEFNNODE }
        method_node.scope.getVariables.select {|v| v.start_with?(prefix) }.each {|v| suggestions << create_proposal(v, prefix, LOCAL_VAR_IMAGE) } unless method_node.nil?
      end
      # Infer type of 'self', suggest methods on that type matching the prefix
      self_type = enclosing_type(offset)
      self_class = "Object"
      self_class = self_type.getCPath.name if self_type
      super_type_names = super_types(self_class)
      super_type_names << self_class # TODO Include namespace!
      super_type_names.each {|t| suggestions << suggest_methods(t, prefix) }
      suggestions.flatten!
      suggestions.uniq {|p| p[:insert] }.sort_by {|p| p[:display] }
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
        prefix_search(index, com.aptana.editor.ruby.index.IRubyIndexConstants::TYPE_DECL) do |r|
          suggestions << create_proposal(r.word.split(INDEX_SEPARATOR).first, prefix, r.word.split(INDEX_SEPARATOR).last == MODULE_SUFFIX ? MODULE_IMAGE : CLASS_IMAGE)
        end
      end
      # TODO Use the AST to grab constants in file/scope
      # Now add constants in project
      prefix_search(index(ENV['TM_FILEPATH']), com.aptana.editor.ruby.index.IRubyIndexConstants::CONSTANT_DECL) do |r|
        suggestions << create_proposal(r.word, prefix, CONSTANT_IMAGE)
      end
      suggestions
    when org.jrubyparser.ast.NodeType::CLASSNODE
      # FIXME This happens when we're in empty space inside class declaration, what about when we're actually on class/super name?
      self_class = node_at_offset.getCPath.name
      suggestions = []
      super_type_names = super_types(self_class)
      super_type_names << self_class # TODO Include namespace!
      super_type_names.each {|t| suggestions << suggest_methods(t, prefix) }
      suggestions.flatten!
      suggestions.uniq {|p| p[:insert] }.sort_by {|p| p[:display] }
    else
      # A node type we currently don't handle
      Ruble::Logger.trace node_at_offset.node_type
      []
    end
  end
  
  private
  
  def extract_super_type_from_ref_key(key)
    parts = key.split('/')
    simple_name = parts[0] # simple name
    namespace = parts[1] # namespace
    if namespace.length > 0
      "#{namespace}::#{simple_name}"
    else
      simple_name
    end
  end
  
  # Breaks a fully qualified type name into namespace and base/simple name
  def namespace_type(fully_qualified_type_name)
    simple_name = fully_qualified_type_name.split("::").last
    last_separator = fully_qualified_type_name.rindex("::")
    namespace = last_separator.nil? ? "" : fully_qualified_type_name[0..last_separator - 1]
    return [namespace, simple_name]
  end
  
  # Actually generate the list of super types and return them all, so we can query up the hierarchy for methods!
  def super_types(type_name)
    return ['Kernel'] if type_name == 'Object'
    # Break type_name up into type name and namespace...
    namespace, type_name = namespace_type(type_name)
    fully_qualified_type_names = []
    # Take the type name and find all the super types and included modules
    all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
      next unless index
      results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::SUPER_REF], "*#{INDEX_SEPARATOR}*#{INDEX_SEPARATOR}#{type_name}#{INDEX_SEPARATOR}#{namespace}#{INDEX_SEPARATOR}*", com.aptana.index.core.SearchPattern::PATTERN_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
      results.each {|r| fully_qualified_type_names << extract_super_type_from_ref_key(r.getWord) } unless results.nil?
    end
    Ruble::Logger.trace "Supertypes of #{type_name}: #{fully_qualified_type_names}"
    # Now grab all the supertypes of these super types!
    to_add = []
    fully_qualified_type_names.each {|name| to_add << super_types(name) }
    fully_qualified_type_names << to_add
    fully_qualified_type_names.flatten.uniq
  end
  
  def prefix_search(index, *rest)
    results = index.query(rest, prefix, com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
    results.each {|r| yield r } if block_given? and results
    results
  end
  
  # Suggest all types and constants that live under the namespace
  def suggest_types_and_constants(namespace)    
    namespace = namespace[0..-3] if namespace.end_with? "::"
    Ruble::Logger.trace namespace
    
    suggestions = []
    search_key = "^(.+)?#{INDEX_SEPARATOR}#{namespace}#{INDEX_SEPARATOR}.*$"    
    all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
      results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::TYPE_DECL], search_key, com.aptana.index.core.SearchPattern::REGEX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
      results.each {|r| suggestions << create_proposal(r.word.split(INDEX_SEPARATOR).first, '', r.word.split(INDEX_SEPARATOR).last == MODULE_SUFFIX ? MODULE_IMAGE : CLASS_IMAGE) } if results
    end
    types = find_type_declarations(namespace)    
    types.each do |t|
      # Collect all the constants declared/assigned under this type!
      constants = t.getChildrenOfType(com.aptana.editor.ruby.core.IRubyElement::CONSTANT)
      constants.each {|c| suggestions << create_proposal(c.name, '', CONSTANT_IMAGE)}
    end
    suggestions
  end
  
  def find_type_declarations(type_name)
    # Need to handle when type_name has namespace!
    namespace, simple_name = namespace_type(type_name)
    Ruble::Logger.trace "Raw: #{type_name}, Namespace: #{namespace}, Simple: #{simple_name}"
    types = []
    docs = []
    all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
      next unless index
      results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::TYPE_DECL], simple_name + INDEX_SEPARATOR + namespace + INDEX_SEPARATOR, com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
      results.each {|r| r.getDocuments.each {|d| docs << d } } unless results.nil?
    end
    docs.flatten!
    Ruble::Logger.trace "Found type declarations in documents: #{docs.join(', ')}"
    # Now iterate over files containing a type with this name...
    docs.each do |doc|
      doc = doc[5..-1] if doc.start_with? "file:" # Need to convert doc from a URI to a filepath
      
      # Parse the file into an AST...
      begin
        # If this is pointing to currently edited file, use our pre-parsed AST so we pick up changes since last save
        ast = (doc == ENV['TM_FILEPATH'] ? root_node : parser.parse(doc, java.io.FileReader.new(doc), parser_config))

        # Traverse the AST into an in-memory model...
        script = com.aptana.editor.ruby.parsing.ast.RubyScript.new(0, -1)
        builder = com.aptana.editor.ruby.parsing.RubyStructureBuilder.new(script)
        com.aptana.editor.ruby.parsing.SourceElementVisitor.new(builder).acceptNode(ast)
        
        # Now grab the matching type(s) from the model...
        possible_types = get_children_recursive(script, com.aptana.editor.ruby.core.IRubyElement::TYPE)
        types << possible_types.select {|t| t.name == simple_name } # FIXME Need to handle namespaces here!
      rescue => e
        # couldn't parse the file
        Ruble::Logger.log_error "Couldn't parse #{doc}: #{e}"
      end
    end
    Ruble::Logger.trace "Grabbed type model elements: #{types.join(', ')}"
    types.flatten!
    types
  end
  
  def get_children_recursive(parent, type)
    children = parent.getChildrenOfType(type) 
    partial = []
    children.each {|c| partial << c; partial << get_children_recursive(c, type) }
    partial.flatten!
    partial
  end
  
  # Suggest global vars with matching prefix
  def suggest_globals
    suggestions = []
    all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
      prefix_search(index, com.aptana.editor.ruby.index.IRubyIndexConstants::GLOBAL_DECL) {|r| suggestions << r.word }
    end
    suggestions.uniq.sort.map {|proposal| create_proposal(proposal, prefix, GLOBAL_VAR_IMAGE) }
  end
  
  def offset
    @offset
  end
  
  def parser
    @parser ||= org.jrubyparser.Parser.new
  end
  
  def parser_config
    org.jrubyparser.parser.ParserConfiguration.new(0, org.jrubyparser.CompatVersion::RUBY1_8)
  end
  
  # Lazily parse the source
  def root_node
    return @root_node unless @root_node.nil?
    
    @src = @io.read
    # If this is an ERB file, we need to replace all non-erb content with whitespaces!
    if ENV['TM_FILENAME'].end_with?(".erb") || ENV['TM_FILENAME'].end_with?(".rhtml")
      Ruble::Logger.trace "Original source: #{@src}"
      @src = replace_non_ruby_code_with_whitespace(@src)
      Ruble::Logger.trace "Fixed source: #{@src}"
    end
    @root_node = parser.parse(ENV['TM_FILENAME'], java.io.StringReader.new(@src), parser_config) rescue nil
    if @root_node.nil?
      # if the syntax is broken because we're mid-edit try to fix common cases of "@|", "$|" or "something.|"
      char = @src[offset, 1]
      case char
      when ".", ":", "@", "$"
        modified_src = @src
        modified_src[offset] = char + "a"
        @root_node = parser.parse(ENV['TM_FILENAME'], java.io.StringReader.new(modified_src), parser_config) rescue nil
      end
    end
    @root_node
  end
  
  def replace_non_ruby_code_with_whitespace(source)
    source = source.gsub(/(%|-)?%>.*?<%(%|=)?/m) {|m| ';' + (' ' * (m.length - 1))}
    source = source.gsub(/^.*?<%(%|=)?/m) {|m| ' ' * m.length }
    last_chunk = source.rindex(/(%|-)?%>.*?$/m, -1)
    if last_chunk
      blah = source.length - last_chunk
      source = source[0...last_chunk] + (' ' * blah)
    end
    source
  end
  
  # Generate a hash representing a proposal with an optional image path
  def create_proposal(proposal, prefix, image = nil, location = nil)
    Ruble::Logger.trace "Creating proposal: #{proposal}"
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
    @prefix = full_prefix

    # find last period/space/:    
    parts = @prefix.split(/(\.|:)+/)
    @prefix = parts.last if parts
    @prefix = '' if @prefix.nil? || @prefix == '.' || @prefix == ':'
    return @prefix
  end
  
  def full_prefix
    return @full_prefix if @full_prefix
    # If we're actually on whitespace, there should be no prefix!
    if @src[offset...offset + 1] =~ /\s/
      @full_prefix = ''
      return @full_prefix
    end
    @full_prefix = @src[0...offset + 1]

    # find last space/newline
    parts = @full_prefix.split(/\s+/)
    @full_prefix = parts.last if parts

    return @full_prefix
  end
  
  # Returns the innermost wrapping type's name
  def get_self(offset)
    type = enclosing_type(offset)
    type.nil? ? "Object" : type.getCPath.name
  end
  
  # Given the root node of the AST and an offset, traverse to find the innermost enclosing type at the offset
  def enclosing_type(offset)
    ClosestSpanningNodeLocator.new.find(root_node, offset) {|node| node.node_type == org.jrubyparser.ast.NodeType::CLASSNODE or node.node_type == org.jrubyparser.ast.NodeType::MODULENODE }
  end

  # Given a type name, we try to reconstruct the type to get at it's methods. Then we generate proposals from that listing
  def suggest_methods(type_name, prefix)
    Ruble::Logger.trace "Suggesting methods for: #{type_name} with prefix: '#{prefix}'"
    begin
      # Sneaky haxor! Try and see if this is a type we can grab in our JRuby runtime and inspect!
      # FIXME Should really be using the user's indices and runtime to determine the methods, but this is a nice workable shortcut for now
      type = eval(type_name)
      # If type is a module, we want singleton_methods and instance_methods. For classes we want instance methods
      methods = []
      if type.class == Module
        methods = type.instance_methods(true)
        methods << type.singleton_methods
        methods = methods.flatten.sort.select {|m| m.start_with?(prefix) }
      else
        methods = type.public_instance_methods(true)
        methods = methods.sort.select {|m| m.start_with?(prefix) }
      end
      Ruble::Logger.trace "Instantiated in JRuby, grabbed methods: #{methods}"
      methods.map {|m| create_proposal(m, prefix, PUBLIC_METHOD_IMAGE, type_name)}
    rescue
      Ruble::Logger.trace "Instantiation in JRuby failed, constructing type from indices"
      # Damn, we have to do things the hard way!
      proposals = []      
      types = find_type_declarations(type_name)
      types.each do |t|
        Ruble::Logger.trace "Iterating over methods on type element: #{t}"
        t.getMethods.each do |m|
          Ruble::Logger.trace "Checking method: #{m.name}, #{m.visibility}"
          Ruble::Logger.trace "Prefix matches method name" if m.name.start_with?(prefix)
          Ruble::Logger.trace "Is public method" if m.visibility == com.aptana.editor.ruby.core.IRubyMethod::Visibility::PUBLIC
          # FIXME Use the correct image given the visibility!
          # FIXME Don't filter out non-public methods if they're on type that encloses us!
          if m.name.start_with?(prefix) && (m.visibility == com.aptana.editor.ruby.core.IRubyMethod::Visibility::PUBLIC)
            Ruble::Logger.trace "Prefix matches and method is public, adding CA entry"
            proposals << create_proposal(m.name, prefix, PUBLIC_METHOD_IMAGE, type_name)
          end
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
    when org.jrubyparser.ast.NodeType::COLON2NODE
      names = []
      # FIXME Handle multiple left nodes!
      names << node.left_node.name
      names << node.name
      names.join("::")
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
      types.flatten!
      types
     when org.jrubyparser.ast.NodeType::CLASSVARNODE
      assigns = ScopedNodeLocator.new.find(enclosing_type(node.position.start_offset))  {|n| (n.node_type == org.jrubyparser.ast.NodeType::CLASSVARASGNNODE || n.node_type == org.jrubyparser.ast.NodeType::CLASSVARDECLNODE) && n.name == node.name }
      types = []
      assigns.each {|a| types << infer(a.value_node) }
      types.flatten!
      types
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
      receiver_types = infer(method_node.getReceiverNode)
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
      implicit_return = last_statement(methods.first.body_node)
      if implicit_return
        case implicit_return.node_type
        when org.jrubyparser.ast.NodeType::IFNODE
          types << infer(last_statement(implicit_return.then_body)) if implicit_return.then_body
          types << infer(last_statement(implicit_return.else_body)) if implicit_return.else_body
        when org.jrubyparser.ast.NodeType::CASENODE
          implicit_return.cases.child_nodes.each do |c|
            types << infer(last_statement(c.body_node)) if c
          end
          types << infer(last_statement(implicit_return.else_node)) if implicit_return.else_node       
        when org.jrubyparser.ast.NodeType::RETURNNODE
          # Ignore this because it's picked up in our explicit return traversal
        else
          types << infer(implicit_return)
        end
      end
      return "Object" if types.empty?
      types.flatten!
      types
    else
      # Should never end up here...
      "Object"
    end
  end
  
  # Given a node, return the last statement in the block (if in one), and unwrap from newline node (if in one)
  def last_statement(node)
    return nil if node.nil?
    node = node.last if node.node_type == org.jrubyparser.ast.NodeType::BLOCKNODE
    node = node.next_node if node.node_type == org.jrubyparser.ast.NodeType::NEWLINENODE
    node
  end
end


# Define a "uniq" method that can take a block to determine what makes the element unique
class Array
  def uniq(&blk)
    require 'set'
    blk ||= lambda {|x| x}
    already_seen = Set.new
    uniq_array = []

    self.each_with_index do |value, i|
      x = blk.call(value)
      unless already_seen.include? x
        already_seen << x
        uniq_array << value
      end
    end
    uniq_array
  end
end