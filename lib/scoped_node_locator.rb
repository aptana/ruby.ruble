require 'node_locator'

# Visitor to find all nodes within a specific scope adhering to a certain condition.
# 
# @author Jason Morrison
class ScopedNodeLocator < NodeLocator

  # Finds the first node preceding the given offset that is accepted by the acceptor.
  # 
  # +scoping_node+
  #            Root Node that contains all nodes to search.
  # +acceptor+
  #            INodeAcceptor defining the condition which the desired node fulfills.
  # @return List of located nodes.
  def find(scoping_node, &acceptor)
    return nil if scoping_node.nil?

    @located_nodes = []
    @acceptor = acceptor

    # Traverse to find all matches
    scoping_node.accept(self)

    # Return the matches
    return @located_nodes
  end

  def handleNode(node)
    @located_nodes << node if @acceptor.call(node)

    return super
  end
end
