require 'ruble'

content_assist 'Type Inference code assist' do |ca|
  ca.scope = 'source.ruby'
  ca.invoke do |context|
    
    # Parse using JRuby parser in embedded JRuby...
    # Grab the JRuby instance we're running in...
    # jruby = ca.java_object.runtime
    # Now parse the active editor's file using the JRuby parser
    # stream = java.io.FileInputStream.new(ENV['TM_FILEPATH'])
    # root_node = jruby.parseInline(stream, ENV['TM_FILENAME'], nil)
    
    # Parse using the jruby parser broken out that provides more detailed offsets for node for IDE usage...
    config = org.jrubyparser.parser.ParserConfiguration.new(0, org.jrubyparser.CompatVersion::RUBY1_8)
    reader = java.io.FileReader.new(ENV['TM_FILEPATH'])
    root_node = org.jrubyparser.Parser.new.parse(ENV['TM_FILENAME'], reader, config)
    # Awesome, we have an AST!
    
    # Now try and get the node that matches our offset!
    offset = context.editor.caret_offset - 1 # Move back one char...    
    require 'offset_node_locator'
    node_at_offset = OffsetNodeLocator.new.getNodeAtOffset(root_node, offset)
    
    # Yay! Now we have the node that we're on. Now we need to work backwards to get the receiver    
    # TODO Determine receiver somehow....
    
    # TODO Trace receiver back to most recent assign
    # TODO Determine type based on assignment
    # TODO Now that we have type, list the methods that we can call on that type
    
    # Prove we've not failed...
    if node_at_offset.nil?
      [root_node.to_s]
    else
      [node_at_offset.node_type.to_s, root_node.to_s]
    end
    nil
  end
end