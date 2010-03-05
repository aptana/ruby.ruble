require 'ruble'

command "Insert ERb's <% .. %> or <%= ..  %>" do |cmd|
  cmd.key_binding = 'CONTROL+SHIFT+.'
  cmd.scope = "text.html.ruby - source, text.xml.ruby - source.ruby"
  cmd.output = :insert_as_snippet
  cmd.input = :selection
  cmd.invoke do |context|
    s = STDIN.read
    case s
    when ""
      "<%${2:=} ${1} %>${0}"
    else
      "<%${2:=} ${1:#{s}} %>${0}"
    end
  end
end
