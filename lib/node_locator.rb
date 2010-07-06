require 'java'

class NodeLocator < com.aptana.editor.ruby.parsing.ast.InOrderVisitor
  
  protected
  def nodeDoesSpanOffset(node, offset)
    # TODO Add a method to org.jruby.ast.Node to implement this on the node itself!
    return false if node.nil? or node.position.nil?
    
    return node.position.start_offset <= offset && node.position.end_offset > offset
  end

  def nodeSpanLength(node)
    return 0 if node.nil? || node.position.nil?
    return node.position.end_offset - node.position.start_offset
  end

  def pushType(type_name)
    @type_name_stack ||= []
    @type_name_stack.push(type_name)
  end

  def popType
    @type_name_stack.pop if @type_name_stack
  end

  def peekType
    return nil if @type_name_stack.empty?
    @type_name_stack.last
  end
end