require 'radrails'

# its ruby, so this just addscommands/snippets in bundle (or replaces those with same name)
# many ruby files could add to a single bundle
bundle 'Ruby' do |bundle|
  bundle.author = "James Edward Gray II et al"
  bundle.author_email_rot13 = "wnzrf@tenlcebqhpgvbaf.arg"
  bundle.copyright = <<END
© Copyright 2009 Aptana Inc. Distributed under GPLv3 and Aptana Source license.

Portions © Copyright 2006 James Edward Gray II, distributed under the terms of the MIT License.
END

  bundle.description = <<END
Support for the Ruby programming language (http://www.ruby-lang.org),
converted from TextMate to RadRails by Aptana.
END

  bundle.git_repo = "git://github.com/aptana/ruby-rrbundle.git"

  # most commands install into a dedicated rails menu
  # See also the alternative, HAML-style syntax in menu.rrmenu
  bundle.menu "Ruby" do |menu|
    # this menu should be shown when any of the following scopes is active:
    menu.scope = [ "source.ruby", "project.rails" ]
    
    #menu.command "Run"
    #menu.command "Run Focused Unit Test"
    #menu.separator
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
    menu.command "New Method"
    menu.command "Hash Pointer - =>"
  end
end
