require 'ruble'
require 'ruble/ui'
require 'ruble/terminal'
require 'escape'

DEFAULT_TASK     = "(default task)".freeze

command 'Run Rake Task' do |cmd|
  cmd.key_binding = 'CONTROL+M2+R'
  cmd.scope = 'source.ruby'
  cmd.output = :discard
  cmd.input = :none
  cmd.invoke do |context|
    Dir.chdir ENV['TM_PROJECT_DIRECTORY']
    tasks = `rake --tasks`
    tasks = [DEFAULT_TASK] + tasks.grep(/^rake\s+(\S+)/) { |t| t.split[1] }
    task = Ruble::UI.request_item( :title   => "Rake Tasks",
                               :prompt  => "Select a task to execute:",
                               :items   => tasks,
                               :button1 => "Run Task")
    if task
      cmd_line = "rake"
      cmd_line << " " << e_sh(task) unless task == DEFAULT_TASK
      Ruble::Terminal.open(cmd_line, ENV['TM_PROJECT_DIRECTORY'])
    end
  end
end
