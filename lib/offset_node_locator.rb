require 'node_locator'

class OffsetNodeLocator < NodeLocator
  
  # Most closely spanning node yet found: @locatedNode
  # Offset sought: @offset

  # Gets the most closely spanning node of the requested offset.
  # 
  # @param rootNode
  #            Node which should span or have children spanning the offset.
  # @param offset
  #            Offset to locate the node of.
  # @return Node most closely spanning the requested offset.
  def getNodeAtOffset(rootNode, offset)
    return nil if rootNode.nil?

    @locatedNode = nil
    @offset = offset

    # Traverse to find closest node
    rootNode.accept(self)

    # Refine the node, if possible, to an inner node not covered by the visitor
    # (Why? Nodes such as ArgumentNode don't like being visited, so they must be handled here.)
    @locatedNode = refine(@locatedNode)

    # Return the node
    return @locatedNode
  end

  # For each node, see if it spans the desired offset. If so, see if it spans it more closely than any previously
  # identified spanning node. If so, record it as the most closely spanning yet.
  def handleNode(iVisited)
    # Skip the NewlineNode since its position is very unaccurate
    if iVisited.node_type != org.jrubyparser.ast.NodeType::NEWLINENODE && nodeDoesSpanOffset(iVisited, @offset)
      # note: careful... should this be <=? I think so; since it traverses in-order, this should find the
      # "most specific" closest node. i.e.
      # def foo;x;end offset at 'x' is a 1-char ScopingNode and 1-char LocalVarNode; it should identify the
      # LocalVarNode, which <= does.
      if @locatedNode.nil? || (nodeSpanLength(iVisited) <= nodeSpanLength(@locatedNode))
        if iVisited.node_type != org.jrubyparser.ast.NodeType::COLON2NODE && iVisited.node_type != org.jrubyparser.ast.NodeType::CONSTNODE
          @locatedNode = iVisited
          handleNode(iVisited.getRestArgNode()) if iVisited.node_type == org.jrubyparser.ast.NodeType::ARGSNODE
        end        
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
    
    # If the search returned an ArgsNode, try to find the specific ArgumentNode matched
    return node if node.node_type != org.jrubyparser.ast.NodeType::ARGSNODE
    if node.getRequiredArgsCount > 0
      return node.pre.child_nodes.select {|c| nodeDoesSpanOffset(c, @offset) }
    end
    return node
  end
end
