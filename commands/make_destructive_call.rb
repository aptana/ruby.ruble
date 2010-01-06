require 'radrails'
require 'radrails/ui'

command 'Add ! to Method in Line' do |cmd|
  cmd.key_binding = 'CTRL+!'
  cmd.scope = 'source.ruby'
  cmd.output = :insert_as_snippet
  cmd.input = :selection, :line
  cmd.invoke do |context|
    require "escape"

    CURSOR = [0xFFFC].pack("U").freeze
    line = context.in.read
    begin
      line[context["TM_LINE_INDEX"].to_i, 0] = CURSOR
    rescue
      exit
    end
    line.sub!(/\b(chomp|chop|collect|compact|delete|downcase|exit|flatten|gsub|lstrip|map|next|reject|reverse|rstrip|slice|sort|squeeze|strip|sub|succs|swapcase|tr|tr_s|uniq|upcase)\b(?!\!)/, "\\1!")
    line = e_sn(line)
    line.sub!(CURSOR, "$0")
    if line == ""
      RadRails::UI.tool_tip "Retry this command without a selection."
      nil
    else
      line  
    end
  end
end
