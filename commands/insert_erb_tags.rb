require 'radrails'

command "Insert ERb's <% .. %> or <%= ..  %>" do |cmd|
  cmd.key_binding = [ :Control, :> ] # FIXME Keybinding is incorrect
  cmd.output = :insert_as_snippet
  cmd.input = :selection
  cmd.invoke do |context|
    "<%= ${0:#{context.in.read}} %>"
  end
end