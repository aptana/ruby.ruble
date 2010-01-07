require 'radrails'
require 'radrails/editor'

command 'Extend Forwardable (Forw)' do |cmd|
  cmd.trigger = 'Forw'
  cmd.scope = 'source.ruby'
  cmd.output = :insert_as_snippet
  cmd.input = :document
  cmd.invoke do |context|
    # Insert Forwardable requires
    CURSOR = [0xFFFC].pack("U").freeze
    line, col = ENV["TM_LINE_NUMBER"].to_i - 1, ENV["TM_LINE_INDEX"].to_i
    code = context.in.read.to_a
    unless ENV.has_key?('TM_SELECTED_TEXT')
      if code[line].nil?  # if cursor was on the last line and it was blank
        code << CURSOR
      else
        code[line][col...col] = CURSOR
      end
    end
    code = code.join
    output = RubyRequires.add_requires(code, "forwardable")
    # FIXME Need to replace the tab trigger prefix!
    output.split(CURSOR).join('${0}extend Forwardable')
  end
end
