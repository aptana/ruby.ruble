require 'content_assist/node_locator'

# Visitor to find the first node that precedes a given offset that satisfies a given condition.
# @author Jason Morrison
class FirstPrecursorNodeLocator < NodeLocator

  # Finds the first node preceding the given offset that is accepted by the acceptor.
  # +param+ rootNode 
  #         Root Node that contains all nodes to search.
  # +param+ offset 
  #         Offset to search backwards from; returned node must occur strictly before this (i.e. end before offset.)
  # +param+ acceptor 
  #         block defining the condition which the desired node fulfills.
  # @return First precursor or nil.
  def find(root_node, offset, &acceptor)
    @locatedNode = nil
    @offset = offset
    @acceptor = acceptor
    
    # Traverse to find closest precursor
    root_node.accept(self)
    
    # Return the match
    return @located_node
  end

  # Searches via InOrderVisitor for the closest precursor.
  def handleNode(node)
# TODO This will include nodes that envelop nodeStart, not only those starting strictly before it.
#      If this behavior is unwanted, remove the || (node.position.start_offset <= offset)
#    in the conditional    
    if (node.position.end_offset <= offset) || (node.position.start_offset <= offset)
      @located_node = node if @acceptor.call(node)  
    end
     
    return super
  end 
end