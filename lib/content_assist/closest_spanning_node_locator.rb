require 'content_assist/node_locator'

# Visitor to find the closest node that spans a given offset that satisfies a given condition.
# 
# @author Jason Morrison
class ClosestSpanningNodeLocator < NodeLocator
  
  # Finds the closest spanning node given offset that is accepted by the acceptor.
  # 
  # +rootNode+
  #            Root Node that contains all nodes to search.
  # +offset+
  #            Offset to search for
  # +acceptor+
  #            INodeAcceptor defining the condition which the desired node fulfills.
  # @return First precursor or null.
  def find(root_node, offset, &node_acceptor)
    return nil if root_node.nil?
    
    @located_node = nil
    @offset = offset
    @acceptor = node_acceptor

    root_node.accept(self)

    # Return the match
    return @located_node
  end

  def handleNode(node)
    if @acceptor.call(node)
      if spans_offset?(node, @offset) && (@located_node.nil? || (span_length(node) <= span_length(@located_node)))
        @located_node = node
      end
    end

    return super
  end
end
