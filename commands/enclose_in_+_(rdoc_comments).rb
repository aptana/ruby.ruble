require 'radrails'

command 'Typewriter' do |cmd|
  cmd.key_binding = 'M1+K'
  cmd.scope = 'source.ruby comment'
  cmd.output = :insert_as_snippet
  cmd.input = :selection, :word
  cmd.invoke do |context|
    s = context.in.read
    case s
    when /^\w+$/
      "+#{s}+$0"
    when ""
      "+$1+$0"
    else
      "<tt>#{s}</tt>"
    end
  end
end
