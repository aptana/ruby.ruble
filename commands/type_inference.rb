require 'ruble'

# This is an experimental code assist impl
content_assist 'Type Inference code assist' do |ca|
  ca.scope = 'source.ruby'
  ca.input = :document
  ca.invoke do |context|
    # Parse using the jruby parser broken out that provides more detailed offsets for node for IDE usage...
    config = org.jrubyparser.parser.ParserConfiguration.new(0, org.jrubyparser.CompatVersion::RUBY1_8)
    src = $stdin.read
    
    offset = context.editor.caret_offset - 1 # Move back one char...
    prefix = prefix(src, offset + 1)
    
    root_node = org.jrubyparser.Parser.new.parse(ENV['TM_FILENAME'], java.io.StringReader.new(src), config) rescue nil
    if root_node.nil?
      # if the syntax is broken because we're mid-edit try to fix common cases of "@|", "$|" or "something.|"
      char = src[offset, 1]
      case char
      when ".", ":", "@", "$"
        modified_src = src
        modified_src[offset] = char + "a"
        root_node = org.jrubyparser.Parser.new.parse(ENV['TM_FILENAME'], java.io.StringReader.new(modified_src), config)
      else
        # Wha? We need to give up!
        Ruble::Logger.log_error "Syntax is busted! Can't parse, so we can't do Code Assist properly."
        context.exit_discard        
      end      
    end
    
    # Awesome, we have an AST!
    
    # Now try and get the node that matches our offset!      
    require 'offset_node_locator'
    node_at_offset = OffsetNodeLocator.new.find(root_node, offset)
    
    require 'index'    
    case node_at_offset.node_type
    when org.jrubyparser.ast.NodeType::CALLNODE # Method call, infer type of receiver, then suggest methods on type
      suggest_methods(infer(root_node, node_at_offset.getReceiverNode), prefix)
      # TODO If we were unable to infer type (beyond "Object"), then we should do a global method name search for any methods with same prefix
    when org.jrubyparser.ast.NodeType::FCALLNODE, org.jrubyparser.ast.NodeType::VCALLNODE # Implicit self
      prefix = prefix(src, offset + 1)
      # Infer type of 'self', suggest methods on that type matching the prefix
      suggestions = suggest_methods(get_self(root_node, offset), prefix)
      # VCall could also be an attempt to refer to a local/dynamic var that is incomplete
      if node_at_offset.node_type == org.jrubyparser.ast.NodeType::VCALLNODE
        # Find innermost method scope and suggest local vars in scope!
        require 'closest_spanning_node_locator'
        method_node = ClosestSpanningNodeLocator.new.find(root_node, offset) {|node| node.node_type == org.jrubyparser.ast.NodeType::DEFNNODE }
        method_node.scope.getVariables.each {|v| suggestions << create_proposal(v, prefix, "icons/local_var_obj.gif") } unless method_node.nil?
      end
      suggestions
    when org.jrubyparser.ast.NodeType::INSTVARNODE, org.jrubyparser.ast.NodeType::INSTASGNNODE, org.jrubyparser.ast.NodeType::CLASSVARNODE, org.jrubyparser.ast.NodeType::CLASSVARASGNNODE
      # Suggest instance/class vars with matching prefix in file/enclosing type
      suggestions = []      
      # Find enclosing type and suggest instance/class vars defined within that type's scope!
      type_node = enclosing_type(root_node, offset)
      require 'scoped_node_locator'
      variables = ScopedNodeLocator.new.find(type_node) {|node| node.node_type == org.jrubyparser.ast.NodeType::INSTASGNNODE || node.node_type == org.jrubyparser.ast.NodeType::CLASSVARASGNNODE || node.node_type == org.jrubyparser.ast.NodeType::CLASSVARDECLNODE }
      variables.each {|v| suggestions << v.name if v.name.start_with? prefix } unless variables.nil?
      suggestions.uniq.sort.map {|proposal| create_proposal(proposal, prefix, proposal.start_with?("@@") ? "icons/class_var_obj.gif" : "icons/instance_var_obj.gif") }
    when org.jrubyparser.ast.NodeType::GLOBALVARNODE, org.jrubyparser.ast.NodeType::GLOBALASGNNODE
      # Suggest global vars with matching prefix
      suggestions = []
      all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
        results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::GLOBAL_DECL],
          prefix, com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
        results.each {|r| suggestions << r.word } unless results.nil?
      end  
      suggestions.uniq.sort.map {|proposal| create_proposal(proposal, prefix, "icons/global_obj.png") }
    when org.jrubyparser.ast.NodeType::COLON2NODE, org.jrubyparser.ast.NodeType::COLON3NODE, org.jrubyparser.ast.NodeType::CONSTNODE
      # Suggest all types with matching prefix
      suggestions = []
      all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
        results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::TYPE_DECL],
          prefix, com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
        results.each {|r| suggestions << create_proposal(r.word.split('/').first, prefix, r.word.split('/').last == "M" ? "icons/module_obj.png" : "icons/class_obj.png") } unless results.nil?
      end
      # TODO Use the AST to grab constants in file/scope
      # Now add constants in project
      results = index(ENV['TM_FILEPATH']).query([com.aptana.editor.ruby.index.IRubyIndexConstants::CONSTANT_DECL],
          prefix, com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
      results.each {|r| suggestions << create_proposal(r.word, prefix, "icons/constant_obj.gif") } unless results.nil?
      suggestions
    else
      # nil
      [node_at_offset.node_type.to_s]
    end
  end
end

# Generate a hash representing a proposal with an optional image path
def create_proposal(proposal, prefix, image = nil)
 hash = { :insert => proposal[prefix.length..-1], :display => proposal }
 hash[:image] = image_url("com.aptana.editor.ruby", image).toString unless image.nil?
 hash
end

# Return an URL that can be used to refer to an image packaged in a plugin
def image_url(plugin_id, path)
  org.eclipse.core.runtime.FileLocator.find(org.eclipse.core.runtime.Platform.getBundle(plugin_id), org.eclipse.core.runtime.Path.new(path), nil)
end

# Given the raw source and an offset, read backwards until we hit a space, period or colon
def prefix(src, offset)
  prefix = src[0...offset]
  
  # find last period/space/:
  index = prefix.rindex('.')
  prefix = prefix[(index + 1)..-1] if !index.nil?
  
  index = prefix.rindex(':')
  prefix = prefix[(index + 1)..-1] if !index.nil?
  
  index = prefix.rindex(' ')
  prefix = prefix[(index + 1)..-1] if !index.nil?
  
  return prefix
end

# Returns the innermost wrapping type's name
def get_self(root_node, offset)
  enclosing_type(root_node, offset).getCPath.name
end

# Given the root node of the AST and an offset, traverse to find the innermost enclosing type at the offset
def enclosing_type(root_node, offset)
  require 'closest_spanning_node_locator'
  ClosestSpanningNodeLocator.new.find(root_node, offset) {|node| node.node_type == org.jrubyparser.ast.NodeType::CLASSNODE or node.node_type == org.jrubyparser.ast.NodeType::MODULENODE }
end

# TODO Need to construct type from it's name into an object and grab the public methods for it
def suggest_methods(type_name, prefix)
  begin
    # Sneaky haxor! Try and see if this is a type we can grab in our JRuby runtime and inspect!
    # Should be really using the user's indices and runtime to determine the methods, but this is a nice workable shortcut for now
    methods = eval(type_name).public_instance_methods(true)
    methods = methods.sort.select {|m| m.start_with? prefix }
    methods.map {|m| create_proposal(m, prefix, "icons/method_public_obj.png")}
  rescue
    # type = find_type(type_name)
    # type.public_methods.select {|proposal| proposal.start_with? prefix }
    
    # FIXME Ugly hack to just show type name we resolved to for debug purposes
    [create_proposal(type_name, prefix, "icons/method_public_obj.png")]
  end  
end

# Returns the name of a Type (string) that we have deemed as the inferred type to try
def infer(root_node, node)
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
    infer(root_node, node.getReceiverNode)
  when org.jrubyparser.ast.NodeType::FCALLNODE, org.jrubyparser.ast.NodeType::VCALLNODE # Implicit self
    get_self(root_node, node.position.start_offset)
  else
    # TODO When its a variable, we need to trace back it's assignments!
    "Object"
  end
end
