require 'radrails'

command "Toggle String / Symbol" do |cmd|
  cmd.key_binding = [ :M1, ":" ] # FIXME Keybinding is incorrect
  cmd.output = :replace_selection
  cmd.input = :selection, :scope
  cmd.scope = "source.ruby string.quoted, source.ruby constant.other.symbol.ruby"
  cmd.invoke do |context|
    case str = context.in.read
      # Handle standard quotes
      when /\A["'](\w+)["']\z/ then ":" + $1
      when /\A:(\w+)\z/ then '"' + $1 + '"'
      # Default case
      else nil # do nothing
    end
  end
end
