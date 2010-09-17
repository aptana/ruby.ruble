require 'content_assist/offset_node_locator'
require 'content_assist/scoped_node_locator' # TODO Move to only the code portions using this (instance/class vars)
require 'content_assist/index' # TODO Move to only the portions of code using this

# A class used to wrap up a pointer to a file, and optionally a selection within that file.
# Used to hold all the delcarations to choose from and then to actually open them in our editor
class Location
  attr_reader :file

  def initialize(file, offset = nil, length = nil)
    @file = file
    @offset = offset
    @length = length || 0
  end

  # Opens an editor to this location
  def open
    require 'ruble/editor'
    editor = Ruble::Editor.go_to(:file => @file)
    editor.selection = [@offset, @length] if editor && @offset
    editor
  end
end

# A class which takes in a src file and an offset and then tries to determine what lives position and trace it back to it's declaration.
class GoToDefinition

  def initialize(io, caret_offset)
    @io = io
    @offset = caret_offset - 1 # Move back one char...
  end

  def run
    Ruble::Logger.log_level = :trace
    return [] if root_node.nil?    

    # Now try and get the node that matches our offset!
    node_at_offset = OffsetNodeLocator.new.find(root_node, offset)

    Ruble::Logger.trace node_at_offset.node_type # Log node type for debug purposes

    # Save up all the locations, pop up a menu UI at the end for user to choose which to open if more than one...
    locations = []
    
    # Now based on the node, trace back to declaration node/file/index entry
    case node_at_offset.node_type
    when org.jrubyparser.ast.NodeType::CALLNODE
      # FIXME infer type of receiver, then find the method def on type hierarchy
      method_name = node_at_offset.name
      # Grab the right indices
      all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
        results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::METHOD_DECL], method_name + com.aptana.editor.ruby.index.IRubyIndexConstants::SEPARATOR.chr, com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
        next unless results
        results.each do |result|
          result.documents.each do |doc|
            # FIXME find in the document!
            locations << Location.new(doc)
          end
        end
      end
    when org.jrubyparser.ast.NodeType::FCALLNODE, org.jrubyparser.ast.NodeType::VCALLNODE # Implicit self
      # FIXME Infer type of 'self', look for methods up the type hierarchy!
      method_name = node_at_offset.name
      # Grab the right indices
      all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
        results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::METHOD_DECL], method_name + com.aptana.editor.ruby.index.IRubyIndexConstants::SEPARATOR.chr, com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
        next unless results
        results.each do |result|
          result.documents.each do |doc|
            # FIXME find in the document!
            locations << Location.new(doc)
          end
        end
      end
    when org.jrubyparser.ast.NodeType::INSTVARNODE
      # Find enclosing type and suggest instance vars defined within that type's scope!
      type_node = enclosing_type(offset)
      variables = ScopedNodeLocator.new.find(type_node) {|node| node.node_type == org.jrubyparser.ast.NodeType::INSTASGNNODE }
      # FIXME Only grab the variable portion on the assignment node
      variables.each {|v| locations << Location.new(ENV['TM_FILEPATH'], v.position.start_offset, v.position.end_offset - v.position.start_offset) } unless variables.nil?
    when org.jrubyparser.ast.NodeType::CLASSVARNODE
      # Find enclosing type and suggest class vars defined within that type's scope!
      type_node = enclosing_type(offset)
      variables = ScopedNodeLocator.new.find(type_node) {|node| node.node_type == org.jrubyparser.ast.NodeType::CLASSVARASGNNODE || node.node_type == org.jrubyparser.ast.NodeType::CLASSVARDECLNODE }
      variables.each {|v| locations << Location.new(ENV['TM_FILEPATH'], v.position.start_offset, v.position.end_offset - v.position.start_offset) } unless variables.nil?
    when org.jrubyparser.ast.NodeType::GLOBALVARNODE, org.jrubyparser.ast.NodeType::GLOBALASGNNODE
      # Search for all declarations of the global
      global_name = node_at_offset.name
      all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
        results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::GLOBAL_DECL], global_name, com.aptana.index.core.SearchPattern::EXACT_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
        next unless results
        results.each do |result|
          result.documents.each do |doc|
            # FIXME find in the document!
            locations << Location.new(doc)
          end
        end
      end
    # COLON3Node = toplevel constant/type name. No namespace
    when org.jrubyparser.ast.NodeType::COLON3NODE, org.jrubyparser.ast.NodeType::CONSTNODE
      constant_name = node_at_offset.name
      all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
        results = []
        # FIXME Search for constant up the scope!
        # search for constant
        partial_results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::CONSTANT_DECL], constant_name, com.aptana.index.core.SearchPattern::EXACT_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
        partial_results.each {|r| results << r }
        # search for type with no namespace
        partial_results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::TYPE_DECL], constant_name + com.aptana.editor.ruby.index.IRubyIndexConstants::SEPARATOR.chr + com.aptana.editor.ruby.index.IRubyIndexConstants::SEPARATOR.chr, com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
        partial_results.each {|r| results << r }

        results.each do |result|
          next unless result
          result.documents.each do |doc|
            # FIXME find in the document!
            locations << Location.new(doc)
          end
        end
      end
    # Colon2Node = namespaced constant/type name
    when org.jrubyparser.ast.NodeType::COLON2NODE
      # TODO Search the indices using the namespace
    # ConstNode = constant/type name with no namespace
    # when org.jrubyparser.ast.NodeType::CONSTNODE
      # TODO Find the declaration of the type/constant.
      # TODO First search enclosing type, then pop up the scopes
    else
      # A node type we currently don't handle. Are there other types of nodes that can be traced back to "declarations"?
      Ruble::Logger.trace node_at_offset.node_type
    end

    # We're done tracing back to possible declarations, pick the one to open
    location = nil
    if locations.size == 1 # There is only one, so use it
      location = locations[0]
    else
      # Pop up a menu UI if there's more than one location so user chooses the one they want
      require 'ruble/ui'
      index = Ruble::UI.menu(locations.map {|l| l.file }) # TODO Display positions, trim file to relative path from index root or maybe display the enclosing type or something instead
      location = locations[index] if index
    end
    # Now open the editor to the file/line of the declaration chosen
    location.open if location
  end

  private
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
  
  # Given the root node of the AST and an offset, traverse to find the innermost enclosing type at the offset
  def enclosing_type(offset)
    require 'content_assist/closest_spanning_node_locator'
    ClosestSpanningNodeLocator.new.find(root_node, offset) {|node| node.node_type == org.jrubyparser.ast.NodeType::CLASSNODE or node.node_type == org.jrubyparser.ast.NodeType::MODULENODE }
  end
end