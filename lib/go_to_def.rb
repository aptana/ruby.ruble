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
      if method_name == "new"
        receiver = node_at_offset.receiver_node
        Ruble::Logger.trace "Tracing back contsructor of receiver #{receiver}"
        if receiver && receiver.respond_to?(:name)
          type_name = receiver.name
          # FIXME Find definition of "initialize" on the type, if it exists!
          all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
            results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::TYPE_DECL], type_name + com.aptana.editor.ruby.index.IRubyIndexConstants::SEPARATOR.chr + com.aptana.editor.ruby.index.IRubyIndexConstants::SEPARATOR.chr, com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
            next unless results
            results.each do |result|
              result.documents.each do |doc|
                locations << find_type(doc, type_name)
              end
            end
          end
        end
      else
        # Grab the right indices
        all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
          Ruble::Logger.trace "Searching #{index} for methods with name #{method_name}"
          results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::METHOD_DECL], method_name + com.aptana.editor.ruby.index.IRubyIndexConstants::SEPARATOR.chr, com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
          next unless results
          results.each do |result|
            result.documents.each do |doc|
              locations << find_method(doc, method_name)
            end
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
            locations << find_method(doc, method_name)
          end
        end
      end
    when org.jrubyparser.ast.NodeType::INSTVARNODE
      # Find enclosing type and suggest instance vars defined within that type's scope!
      type_node = enclosing_type(offset)
      variables = ScopedNodeLocator.new.find(type_node) {|node| node.node_type == org.jrubyparser.ast.NodeType::INSTASGNNODE }
      # FIXME Only grab the variable portion on the assignment node
      variables.each {|v| locations << create_location(ENV['TM_FILEPATH'], v.position) } unless variables.nil?
    when org.jrubyparser.ast.NodeType::CLASSVARNODE
      # Find enclosing type and suggest class vars defined within that type's scope!
      type_node = enclosing_type(offset)
      variables = ScopedNodeLocator.new.find(type_node) {|node| node.node_type == org.jrubyparser.ast.NodeType::CLASSVARASGNNODE || node.node_type == org.jrubyparser.ast.NodeType::CLASSVARDECLNODE }
      variables.each {|v| locations << create_location(ENV['TM_FILEPATH'], v.position) } unless variables.nil?
    when org.jrubyparser.ast.NodeType::GLOBALVARNODE, org.jrubyparser.ast.NodeType::GLOBALASGNNODE
      # Search for all declarations of the global
      global_name = node_at_offset.name
      all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
        results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::GLOBAL_DECL], global_name, com.aptana.index.core.SearchPattern::EXACT_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
        next unless results
        results.each do |result|
          result.documents.each do |doc|
            locations << find_global(doc, global_name)
          end
        end
      end
    # COLON3Node = toplevel constant/type name. No namespace
    when org.jrubyparser.ast.NodeType::COLON3NODE, org.jrubyparser.ast.NodeType::CONSTNODE
      constant_name = node_at_offset.name
      all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
        # FIXME Search for constant up the scope!
        # search for constant
        results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::CONSTANT_DECL], constant_name, com.aptana.index.core.SearchPattern::EXACT_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
        if results
          results.each do |result|
            next unless result
            result.documents.each do |doc|
              # FIXME find in the document!
              locations << Location.new(doc)
            end
          end
        end
        
        # search for type with no namespace
        results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::TYPE_DECL], constant_name + com.aptana.editor.ruby.index.IRubyIndexConstants::SEPARATOR.chr + com.aptana.editor.ruby.index.IRubyIndexConstants::SEPARATOR.chr, com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
        if results
          results.each do |result|
            next unless result
            result.documents.each do |doc|
              locations << find_type(doc, constant_name)
            end
          end
        end
      end
    # Colon2Node = namespaced constant/type name
    when org.jrubyparser.ast.NodeType::COLON2NODE
      # TODO Also search for namespaced constants
      type_name = node_at_offset.name
      namespace = namespace(node_at_offset)
      all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
        # search for type with namespace
        results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::TYPE_DECL], type_name + com.aptana.editor.ruby.index.IRubyIndexConstants::SEPARATOR.chr + namespace + com.aptana.editor.ruby.index.IRubyIndexConstants::SEPARATOR.chr, com.aptana.index.core.SearchPattern::PREFIX_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
        if results
          results.each do |result|
            next unless result
            result.documents.each do |doc|
              locations << find_type(doc, type_name)
            end
          end
        end
      end
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
      # FIXME Prioritize the entries. For example, if I'm resolving ActionControl::Base, prefer a path ending in 'actioncontroller/base.rb'
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
    org.jrubyparser.parser.ParserConfiguration.new(0, org.jrubyparser.CompatVersion::BOTH)
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
  
  # Parse the document, traverse the AST looking for a method node with this name, then return fine grained location
  def find_method(doc, name)
    root = parse_url(doc)
    if root
      Ruble::Logger.trace "Searching for method nodes with name: #{name}"
      matching_nodes = ScopedNodeLocator.new.find(root)  {|node| (node.node_type == org.jrubyparser.ast.NodeType::DEFNNODE || node.node_type == org.jrubyparser.ast.NodeType::DEFSNODE) && node.name == name }
      if matching_nodes && matching_nodes.size > 0
        return create_location(doc, matching_nodes.first.name_node.position)
      end
    end
    Location.new(doc)
  end
  
  def find_global(doc, name)
    root = parse_url(doc)
    if root
      Ruble::Logger.trace "Searching for global nodes with name: #{name}"
      matching_nodes = ScopedNodeLocator.new.find(root)  {|node| node.node_type == org.jrubyparser.ast.NodeType::GLOBALASGNNODE && node.name == name }
      if matching_nodes && matching_nodes.size > 0
        return create_location(doc, matching_nodes.first.position)
      end
    end
    Location.new(doc)
  end
  
  def find_type(doc, name)
    root = parse_url(doc)
    if root
      Ruble::Logger.trace "Searching for type nodes with name: #{name}"
      matching_nodes = ScopedNodeLocator.new.find(root)  {|node| (node.node_type == org.jrubyparser.ast.NodeType::CLASSNODE || node.node_type == org.jrubyparser.ast.NodeType::MODULENODE) && node.getCPath.name == name }
      if matching_nodes && matching_nodes.size > 0
        return create_location(doc, matching_nodes.first.getCPath.position)
      end
    end
    Location.new(doc)
  end
  
  def create_location(filename, node_position)
    Location.new(filename, node_position.start_offset, node_position.end_offset - node_position.start_offset)
  end
  
  def parse_url(file_url)
    filename = file_url
    filename = filename[5..-1] if filename.start_with? "file:"
    Ruble::Logger.trace "Parsing file #{filename}"
    parser.parse(filename, java.io.FileReader.new(filename), parser_config) rescue nil
  end
  
  def namespace(colon2node)
    if colon2node.respond_to?(:left_node)
      left = colon2node.left_node
      return full_name(left) if left
    end
    ""
  end
  
  def full_name(node)
    if node.respond_to?(:left_node)
      left = node.left_node
      return "#{full_name(left)}::#{node.name}" if left
    end
    node.name
  end
end