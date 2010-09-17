require 'ruble/editor'
require 'content_assist/offset_node_locator'
require 'content_assist/index'

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

    # Now based on the node, trace back to declaration node/file/index entry
    # TODO Save up all the locations, pop up a menu UI at the end for user to choose which to open
    locations = []
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
            # TODO find in the document!
            locations << doc
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
            # TODO find in the document!
            locations << doc
          end
        end
      end
    when org.jrubyparser.ast.NodeType::INSTVARNODE, org.jrubyparser.ast.NodeType::INSTASGNNODE, org.jrubyparser.ast.NodeType::CLASSVARNODE, org.jrubyparser.ast.NodeType::CLASSVARASGNNODE
      # TODO Find the declaration of the var in this file
    when org.jrubyparser.ast.NodeType::GLOBALVARNODE, org.jrubyparser.ast.NodeType::GLOBALASGNNODE
      # Search for all declarations of the global
      global_name = node_at_offset.name
      all_applicable_indices(ENV['TM_FILEPATH']).each do |index|
        results = index.query([com.aptana.editor.ruby.index.IRubyIndexConstants::GLOBAL_DECL], global_name, com.aptana.index.core.SearchPattern::EXACT_MATCH | com.aptana.index.core.SearchPattern::CASE_SENSITIVE)
        next unless results
        results.each do |result|
          result.documents.each do |doc|
            # TODO find in the document!
            locations << doc
          end
        end
      end
    when org.jrubyparser.ast.NodeType::COLON2NODE, org.jrubyparser.ast.NodeType::COLON3NODE, org.jrubyparser.ast.NodeType::CONSTNODE
      # TODO Find the declaration of the type/constant
    else
      # A node type we currently don't handle
      Ruble::Logger.trace node_at_offset.node_type
    end

    # TODO Now pop up a menu UI if there's more than one location so user chooses the one they want
    # TODO Now open the editor to the file/line of the declaration chosen
    locations.each {|l| Ruble::Editor.go_to(:file => l) }
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
end