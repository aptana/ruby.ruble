require 'radrails'
require 'radrails/terminal'

command 'Run' do |cmd|
  cmd.key_binding = 'M1+R'
  cmd.scope = 'source.ruby'
  cmd.output = :discard
  cmd.input = :none
  cmd.invoke {|context| RadRails::Terminal.open("ruby -KU -- \"#{context['TM_FILEPATH']}\"", context['TM_PROJECT_DIRECTORY']) }
end
