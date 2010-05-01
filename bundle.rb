require 'ruble'

# its ruby, so this just addscommands/snippets in bundle (or replaces those with same name)
# many ruby files could add to a single bundle
bundle do |bundle|
  bundle.author = 'Christopher Williams'
  bundle.copyright = <<END
� Copyright 2010 Aptana Inc. Distributed under the MIT license.

Portions � Copyright 2006 James Edward Gray II, distributed under the terms of the MIT License.
END

  bundle.display_name = 'Ruby'
  bundle.description = <<END
Support for the Ruby programming language (http://www.ruby-lang.org),
converted from TextMate to Ruble by Aptana.
END

  bundle.repository = "git://github.com/aptana/ruby.ruble.git"
  # Folding
  start_folding = /(\s*+(module|class|def(?!.*\bend\s*$)|unless|if|case|begin|for|while|until|^=begin|("(\\.|[^"])*+"|'(\\.|[^'])*+'|[^#"'])*(\s(do|begin|case)|(?<!\$)[-+=&|*\/~%^<>~]\s*+(if|unless)))\b(?![^;]*+;.*?\bend\b)|("(\\.|[^"])*+"|'(\\.|[^'])*+'|[^#"'])*(\{(?![^}]*+\})|\[(?![^\]]*+\]))).*$|[#].*?\(fold\)\s*+$/
  end_folding = /((^|;)\s*+end\s*+([#].*)?$|(^|;)\s*+end\..*$|^\s*+[}\]],?\s*+([#].*)?$|[#].*?\(end\)\s*+$|^=end)/
  bundle.folding['source.ruby'] = start_folding, end_folding
  # Indentation
  increase_indent = /(?x)^(\s*(module|class|def|unless|if|else|elsif|case|when|begin|rescue|ensure|for|while|until|(?=.*?\b(do|begin|case|if|unless)\b)("(\\.|[^\\"])*+"|'(\\.|[^\\'])*+'|[^#"'])*(\s(do|begin|case)|[-+=&|*\/~%^<>~](?<!\$.) \s*+ (if|unless)))\b(?![^;]*+;.*?\bend\b)|("(\\.|[^\\"])*+"|'(\\.|[^\\'])*+'|[^#"'])*(\{(?![^}]*+\})|\[(?![^\]]*+\]))).*$/
  decrease_indent = /^\s*([}\]]\s*$|(end|rescue|ensure|else|elsif|when)\b)/
  bundle.indent['source.ruby'] = increase_indent, decrease_indent
  
  # most commands install into a dedicated rails menu
  # See also the alternative, HAML-style syntax in menu.rrmenu
  bundle.menu "Ruby" do |menu|
    # this menu should be shown when any of the following scopes is active:
    menu.scope = [ "source.ruby", "project.rails" ]
    
    menu.command "Run"
    menu.command "Run Focused Unit Test"
    menu.command 'Run Tests in Current File'
    menu.command "Run Rake Task"
    menu.separator
    menu.command "Documentation for Word"
    menu.menu "RDoc" do |rdoc|
      rdoc.command 'Show for Current File / Project'
      rdoc.separator
      rdoc.menu 'Format' do |format|
        format.command "Bold"
        format.command "Italic"
        format.command "Typewriter"
      end
      rdoc.separator
      rdoc.command "Omit"
    end
    menu.separator   
    menu.command "Open require"
    menu.command "Validate Syntax"
    menu.command "Validate Syntax (ERB)"
    menu.separator
    menu.command "Execute Line / Selection as Ruby"
    menu.command "Execute and Update '# =>' Markers"
    menu.separator
    menu.command "Insert Missing requires"
    menu.command "Add ! to Method in Line"
    menu.command "Toggle String / Symbol"
    menu.command "Insert ERb's <% .. %> or <%= ..  %>"
    menu.separator
    menu.command 'Completion: Ruby (rcodetools)'
    menu.separator
    menu.command "New Method"
    menu.command "Toggle 'do ... end' / '{ ... }'"
    menu.command "Hash Pointer - =>"
  end
end

# Extend Ruble::Editor to add special ENV vars
module Ruble
  class Editor
    unless method_defined?(:modify_env_pre_ruby_bundle)
      alias :modify_env_pre_ruby_bundle :modify_env
      def modify_env(scope, env)
        env_hash = modify_env_pre_ruby_bundle(scope, env)
        if scope.start_with? "source.ruby"
          env_hash['TM_COMMENT_START'] = "# "
          env_hash.delete('TM_COMMENT_END')
          env_hash['TM_COMMENT_START_2'] = "=begin"
          env_hash['TM_COMMENT_END_2'] = "=end"
          env_hash.delete('TM_COMMENT_DISABLE_INDENT')
        end
        env_hash
      end
    end
  end
end