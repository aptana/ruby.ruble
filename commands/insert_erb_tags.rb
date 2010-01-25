require 'radrails'

command "Insert ERb's <% .. %> or <%= ..  %>" do |cmd|
  cmd.key_binding = 'Control+>'
  cmd.output = :insert_as_snippet
  cmd.input = :selection
  cmd.invoke do |context|
    "<%= ${0:#{STDIN.read}} %>"
  end
end
