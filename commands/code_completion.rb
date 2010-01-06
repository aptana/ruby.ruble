require 'radrails'
require 'radrails/ui'

command "Completion: Ruby (rcodetools)" do |cmd|
  cmd.key_binding = 'M3+ESC'
  cmd.output = :insert_as_text
  cmd.input = :document
  cmd.scope = "source.ruby"
  cmd.invoke do |context|
	require "pathname"

	TM_RUBY    = context["TM_RUBY"] || "ruby"
	RCODETOOLS = "#{context['TM_BUNDLE_SUPPORT']}/vendor/rcodetools"
	
	RAILS_DIR = nil
	dir = File.dirname(context["TM_FILEPATH"]) rescue context["TM_PROJECT_DIRECTORY"]
	if dir
	  dir = Pathname.new(dir)
	  loop do
	    if (dir + "config/environment.rb").exist?
	      Object.send(:remove_const, :RAILS_DIR)
	      RAILS_DIR = dir.to_s
	      break
	    end
	    
	    break if dir.to_s == "/"
	    
	    dir += ".."
	  end
	end
	
	command     = <<END_COMMAND.tr("\n", " ").strip
"#{TM_RUBY}"
-I "#{RCODETOOLS}/lib"
--
"#{RCODETOOLS}/bin/rct-complete"
#{"-r \"#{RAILS_DIR}/config/environment.rb\"" if RAILS_DIR}
--line=#{context['TM_LINE_NUMBER']}
--column=#{context['TM_LINE_INDEX']}
2> /dev/null
END_COMMAND

    result = IO.popen(command, "r+") do |io|
      io.write context.in.read
      io.close_write # let the process know you've given it all the data 
      io.read
    end

	completions = result.to_a.map { |l| l.strip }.select { |l| l.length > 0 && l =~ /\S/ }

	if not $?.success?
	  RadRails::UI.tool_tip "Parse error."
	elsif completions.size == 1
	  selected = completions.first
	elsif completions.size > 1
	  selected = completions[RadRails::UI.menu(completions)] rescue exit
	else
	  RadRails::UI.tool_tip "No matches were found."
	end
	
	if selected
	  selected.sub(/\A#{Regexp.escape(context['TM_CURRENT_WORD'].to_s)}/, "")
	else
	  nil
	end
  end
end