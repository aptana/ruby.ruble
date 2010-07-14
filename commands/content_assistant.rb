require 'ruble'

# This is an experimental code assist impl
content_assist 'Type Inference code assist' do |ca|
  ca.scope = 'source.ruby'
  ca.input = :document
  ca.invoke do |context|
    require 'content_assist'
    ContentAssistant.new($stdin, context.editor.caret_offset).assist
  end
end

