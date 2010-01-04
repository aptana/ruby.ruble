require 'radrails'
require 'radrails/logger'
require 'radrails/editor'

command "Validate Syntax" do |cmd|
  cmd.key_binding = [ :M1, :V ] # FIXME Keybinding is incorrect
  cmd.output = :show_as_tooltip
  cmd.input = :document
  cmd.scope = "source.ruby"
  cmd.invoke do |context|
    RadRails::Logger.log_level = :trace
    result = IO.popen("ruby -wc 2>&1", "r+") do |io|
      io.write context.in.read
      io.close_write # let the process know you've given it all the data 
      io.read
    end
    RadRails::Editor.go_to :line => $1 if result =~ /-:(\d+):/
    result
  end
end
