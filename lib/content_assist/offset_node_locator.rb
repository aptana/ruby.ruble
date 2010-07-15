require 'content_assist/closest_spanning_node_locator'

# Special case of closests spanning node locator. Accepts every node type except newlines
class OffsetNodeLocator

  # Gets the most closely spanning node of the requested offset.
  # 
  # +root_node+
  #            Node which should span or have children spanning the offset.
  # +offset+
  #            Offset to locate the node of.
  # @return Node most closely spanning the requested offset.
  def find(root_node, offset)
    ClosestSpanningNodeLocator.new.find(root_node, offset) {|node| node.node_type != org.jrubyparser.ast.NodeType::NEWLINENODE }
  end
end
