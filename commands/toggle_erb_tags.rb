require 'radrails'
# TODO This needs to be tested My guess is it won't work as is (especially because of the scope declared)
command 'Toggle ERb Tags' do |cmd|
  cmd.key_binding = :CTRL, :>
  cmd.scope = 'source.ruby.embedded, source.ruby.rails.embedded, comment.block.erb, meta.erb'
  cmd.output = :insert_as_snippet
  cmd.input = :selection, :scope
  cmd.invoke do |context|
    require "escape"
    require "enumerator"
    
    TAGS = %w[<%= <%# <%- <%].freeze
    
    # locate caret (Allan's code)
    line = context['TM_LINE_NUMBER'].to_i - context['TM_INPUT_START_LINE'].to_i
    col  = context['TM_LINE_INDEX'].to_i
    if context['TM_LINE_NUMBER'].to_i == context['TM_INPUT_START_LINE'].to_i
      col -= context['TM_INPUT_START_LINE_INDEX'].to_i
    end
    
    # read input
    input = context.in.read
    
    # snippetize output
    lines       = input.to_a
    lines[line] = e_sn(lines[line][0...col]) + "${0}" + e_sn(lines[line][col..-1])
    output      = lines.enum_with_index.inject(String.new) do |out, (l, i)|
      i == line ? out + l : out + e_sn(l)
    end
    
    # swap ERb tags
    result = output.sub(/\A<%[-#=]?/) { |match| TAGS[TAGS.index(match) - 1] }
    if result[2] == ?-
      result.sub!(/%>\Z/, "-%>")
    else
      result.sub!(/-%>\Z/, "%>")
    end
    result
  end
end
