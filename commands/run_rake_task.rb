require 'radrails'
require 'radrails/ui'
require 'radrails/terminal'
require 'escape'

DEFAULT_TASK     = "(default task)".freeze

command 'Run Rake Task' do |cmd|
  cmd.key_binding = 'CONTROL+M2+R'
  cmd.scope = 'source.ruby'
  cmd.output = :discard
  cmd.input = :none
  cmd.invoke do |context|
    Dir.chdir context['TM_PROJECT_DIRECTORY']
    tasks = `rake --tasks`
    tasks = [DEFAULT_TASK] + tasks.grep(/^rake\s+(\S+)/) { |t| t.split[1] }
    task = RadRails::UI.request_item( :title   => "Rake Tasks",
                               :prompt  => "Select a task to execute:",
                               :items   => tasks,
                               :button1 => "Run Task")
    task = nil if task == DEFAULT_TASK
    
    cmd_line = "rake"
    cmd_line << " " << e_sh(task) unless task.nil?
    RadRails::Terminal.open(cmd_line, context['TM_PROJECT_DIRECTORY'])
  end
end
