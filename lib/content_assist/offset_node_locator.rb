require 'content_assist/node_locator'

# FIXME Should be able to make a special subclass of ClosestSpanningNodeLocator that accepts everything (except newlines)
class OffsetNodeLocator < NodeLocator

  # Gets the most closely spanning node of the requested offset.
  # 
  # +root_node+
  #            Node which should span or have children spanning the offset.
  # +offset+
  #            Offset to locate the node of.
  # @return Node most closely spanning the requested offset.
  def find(root_node, offset)
    return nil if root_node.nil?

    @locatedNode = nil
    @offset = offset

    # Traverse to find closest node
    root_node.accept(self)

    # Refine the node, if possible, to an inner node not covered by the visitor
    # (Why? Nodes such as ArgumentNode don't like being visited, so they must be handled here.)
    @locatedNode = refine(@locatedNode)

    # Return the node
    return @locatedNode
  end

  # For each node, see if it spans the desired offset. If so, see if it spans it more closely than any previously
  # identified spanning node. If so, record it as the most closely spanning yet.
  def handleNode(node)
    # Skip the NewlineNode since its position is very unaccurate
    if node.node_type != org.jrubyparser.ast.NodeType::NEWLINENODE && spans_offset?(node, @offset)
      if @locatedNode.nil? || (span_length(node) <= span_length(@locatedNode))
        @locatedNode = node
        handleNode(node.getRestArgNode()) if node.node_type == org.jrubyparser.ast.NodeType::ARGSNODE
      end
    end

    # TODO Since we are moving in order, if a spanning node has been located, and the current node does
    # not span, we can effectively return early since no subsequent nodes should span. Not doing this
    # now, just in case InOrderVisitor proves to not quite be in-order (i.e. offsets reported are off.)
    return super
  end
  
  private
  def refine(node)
    return nil if node.nil?
    # TODO Fix this in InOrderVisitor? We can visit pre and post children!
    
    # If the search returned an ArgsNode, try to find the specific ArgumentNode matched
    return node if node.node_type != org.jrubyparser.ast.NodeType::ARGSNODE
    # Return specific arg if there are some
    return node.pre.child_nodes.select {|c| nodeDoesSpanOffset(c, @offset) } if node.getRequiredArgsCount > 0
    node
  end
end
