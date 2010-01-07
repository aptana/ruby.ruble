require 'radrails'

command 'YAML.load(file)' do |cmd|
  cmd.trigger = 'Yl'
  cmd.scope = 'source.ruby'
  cmd.output = :insert_as_snippet
  cmd.input = :document
  cmd.invoke do |context|
    require 'ruby_requires'
    # Insert yaml requires
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
    output = RubyRequires.add_requires(code, "yaml")
    output.split(CURSOR).join('${0}File.open("${1:path_to_file}.yaml") { |${2:file}| YAML.load(${2:file}) }')
  end
end
