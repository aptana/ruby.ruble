require 'radrails'
require 'radrails/editor'

command 'Validate Syntax (ERB)' do |cmd|
  cmd.key_binding = :Control, :Shift, :V
  cmd.scope = 'text.html.ruby, text.html source.ruby'
  cmd.output = :show_as_tooltip
  cmd.input = :document
  cmd.invoke do |context|
    result = IO.popen("erb -T - -x | ruby -c 2>&1", "r+") do |io|
      io.write context.in.read
      io.close_write # let the process know you've given it all the data 
      io.read
    end
    RadRails::Editor.go_to :line => $1.to_i if result =~ /-:(\d+):/
    result
  end
end
