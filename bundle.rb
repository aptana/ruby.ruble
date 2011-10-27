require 'ruble'

# its ruby, so this just addscommands/snippets in bundle (or replaces those with same name)
# many ruby files could add to a single bundle
bundle do |bundle|
  bundle.author = 'Christopher Williams et al'
  bundle.copyright = <<END
(C) Copyright 2010 Aptana Inc. Distributed under the MIT license.

Portions (C) Copyright 2006 James Edward Gray II, distributed under the terms of the MIT License.
END

  bundle.display_name = 'Ruby'
  bundle.description = <<END
Support for the Ruby programming language (http://www.ruby-lang.org),
converted from TextMate to Ruble by Aptana.

Special thanks to our contributors:

  Kenny Ortmann (http://github.com/yairgo)
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
    menu.command "Add '# =>' Marker"
    menu.separator
    menu.command "Insert Missing requires"
    menu.command "Add ! to Method in Line"
    menu.command "Toggle String / Symbol"
    menu.command "Insert ERb's <% .. %> or <%= ..  %>"
    menu.separator
    menu.menu "Declarations" do |decl|
      decl.command "New Method"
      decl.separator
      decl.command 'begin ... rescue ... end'
      decl.command 'case ... end'
      decl.command 'when ...'
      decl.command 'def ... end'
      decl.command 'if ... end'
      decl.command 'if ... else ... end'
      decl.command 'elsif ...'      
      decl.command 'unless ... end'
      decl.command 'while ... end'
      decl.command 'until ... end'
      decl.separator
      decl.menu 'Classes and Modules' do |classes|
         classes.command 'class .. end'
         classes.command 'class .. initialize .. end'
         classes.command 'class .. < ParentClass .. initialize .. end'
         classes.command 'ClassName = Struct .. do .. end'
         classes.command 'class BlankSlate .. initialize .. end'
         classes.command 'class .. < DelegateClass .. initialize .. end'
         classes.command 'class << self .. end'
         classes.separator
         classes.command 'module .. end'
         classes.command 'module .. module_function .. end'
         classes.command 'module .. ClassMethods .. end'
      end
      decl.menu 'Methods' do |methods|
        methods.command 'attr_reader ..'
        methods.command 'attr_writer ..'
        methods.command 'attr_accessor ..'
        methods.separator
        methods.command 'include Enumerable ..'
        methods.command 'include Comparable ..'
        methods.separator
        methods.command 'Extend Forwardable (Forw)'
        methods.separator
        methods.command 'def self .. end'
        methods.command 'def method_missing .. end'
        methods.command 'def_delegator ..'
        methods.command 'def_delegators ..'
        methods.separator
        methods.command 'alias_method ..'
      end
      decl.command '__END__'  
      decl.separator
      decl.command '#!/usr/bin/env ruby -wKU'
      # decl.command 
      decl.command 'require ".."'
      decl.command 'require_gem ".."'
      decl.command 'application { .. }'
      decl.command 'usage_if()'
      decl.command 'usage_unless()'
    end
    menu.menu "Iterators" do |iters|
      iters.menu "Arrays" do |arrays|
        arrays.command 'Array.new(10) { |i| .. }'
        arrays.separator
        arrays.command 'delete_if { |e| .. }'
        arrays.command 'fill(range) { |i| .. }'
        arrays.command 'flatten_once()'
        arrays.command 'zip(enums) { |row| .. }'
      end
      iters.menu "Counting" do |counting|
        counting.command 'downto(0) { |n| .. }'
        counting.command 'step(2) { |e| .. }'
        counting.command 'times { |n| .. }'
        counting.command 'upto(1.0/0.0) { |n| .. }'
        counting.separator
        counting.command 'loop { .. }'
      end
      iters.menu "Each Element" do |each_element|
        each_element.command 'each { |e| .. }'
        each_element.command 'each_byte { |byte| .. }'
        each_element.command 'each_char { |chr| .. }'
        each_element.command 'each_cons(..) { |group| .. }'
        each_element.command 'each_index { |i| .. }'
        each_element.command 'each_key { |key| .. }'
        each_element.command 'each_line { |line| .. }'
        each_element.command 'each_pair { |name, val| .. }'
        each_element.command 'each_slice(..) { |group| .. }'
        each_element.command 'each_value { |val| .. }'
        each_element.command 'each_with_index { |e, i| .. }'
        each_element.command 'reverse_each { |e| .. }'
        each_element.separator
        each_element.command 'inject(init) { |mem, var| .. }'
        each_element.separator
        each_element.command 'map { |e| .. }'
        each_element.command 'map_with_index { |e, i| .. }'
      end
      iters.menu "Ordering" do |ordering|
        ordering.command 'sort { |a, b| .. }'
        ordering.command 'sort_by { |e| .. }'
        ordering.separator
        ordering.command 'randomize()'
      end
      iters.menu "Searching and Selection" do |searching|
        searching.command 'all? { |e| .. }'
        searching.command 'any? { |e| .. }'
        searching.command 'classify { |e| .. }'
        searching.command 'collect { |e| .. }'
        searching.command 'detect { |e| .. }'
        searching.command 'fetch(name) { |key| .. }'
        searching.command 'find { |e| .. }'
        searching.command 'find_all { |e| .. }'
        searching.command 'grep(/pattern/) { |match| .. }'
        searching.command 'max { |a, b| .. }'
        searching.command 'min { |a, b| .. }'
        searching.command 'partition { |e| .. }'
        searching.command 'reject { |e| .. }'
        searching.command 'select { |e| .. }'
      end
      iters.menu "Strings" do |strings|
        strings.command 'sub(/../) { |match| .. }'
        strings.command 'gsub(/../) { |match| .. }'
        strings.separator
        strings.command 'scan(/../) { |match| .. }'
      end
    end
    menu.menu "Blocks" do |blocks|
      blocks.command "Toggle 'do ... end' / '{ ... }'"
      blocks.separator
      blocks.command 'Insert { |variable| ... }'
      blocks.command 'Insert do |variable| ... end'
      blocks.separator
      blocks.command 'lambda { |args| .. }'
    end
    menu.menu "Hashes" do |hashes|
      hashes.command 'Hash.new { |hash, key| hash[key] = .. }'
      hashes.separator
      hashes.command 'Hash Pair - :key => "value"'
      hashes.command "Hash Pointer - =>"
    end
    menu.menu "Files" do |files|
      files.command 'open("path_or_url", "w") { |io| .. }'
      files.separator
      files.command 'File.foreach ("..") { |line| .. }'
      files.command 'File.read("..")'
      files.command 'File.open("..") { |file| .. }'
      files.separator
      files.command 'Dir.glob("..") { |file| .. }'
      files.command 'Dir[".."]'
      files.command 'directory()'
      files.command 'path_from_here( .. )'
      files.separator
      files.command 'unix_filter { .. }'
      files.command 'option_parse { .. }'
      files.command 'option(..)'
    end
    menu.menu "Tests" do |tests|
      tests.command 'class .. < Test::Unit::TestCase .. end'
      tests.command 'def test_ .. end'
      tests.command 'require "tc_.." ..'
      tests.separator
      tests.command 'assert(..)'
      tests.command 'assert_equal(..)'
      tests.command 'assert_not_equal(..)'
      tests.command 'assert_in_delta(..)'
      tests.command 'assert_instance_of(..)'
      tests.command 'assert_kind_of(..)'
      tests.command 'assert_nil(..)'
      tests.command 'assert_not_nil(..)'
      tests.command 'assert_match(..)'
      tests.command 'assert_no_match(..)'
      tests.command 'assert_operator(..)'
      tests.command 'assert_raise(..) { .. }'
      tests.command 'assert_nothing_raised(..) { .. }'
      tests.command 'assert_respond_to(..)'
      tests.command 'assert_same(..)'
      tests.command 'assert_not_same(..)'
      tests.command 'assert_send(..)'
      tests.command 'assert_throws(..) { .. }'
      tests.command 'assert_nothing_thrown { .. }'
      tests.command 'flunk(..)'
      tests.separator
      tests.command 'Benchmark.bmbm do .. end'
      tests.command 'results.report(..) { .. }'
    end
    menu.menu "Serialization" do |serial|
      serial.command "Marshal.dump(.., file)"
      serial.command 'Marshal.load(obj)'
      serial.separator
      serial.command 'PStore.new( .. )'
      serial.command 'transaction( .. ) { .. }'
      serial.separator
      serial.command 'YAML.dump(.., file)'
      serial.command 'YAML.load(file)'
      serial.separator
      serial.command 'xmlread(..)'
      serial.command 'xpath(..) { .. }'
    end
    menu.menu "Idioms" do |idioms|
      idioms.command 'class_from_name()'
      idioms.command 'deep_copy(..)'
      idioms.command 'singleton_class()'
      idioms.command 'word_wrap()'
    end
    menu.menu "Rake" do |rake|
      rake.command "Run Rake Task"
      rake.separator
      rake.command 'namespace :.. do .. end'
      rake.command 'task :task_name => [:dependent, :tasks] do .. end'
    end
  end
end

smart_typing_pairs['source.ruby'] = ['"', '"', '|', '|', '(', ')', '{', '}', '[', ']', "'", "'", '`', '`']

env 'source.ruby' do |e|
  e['TM_COMMENT_START'] = "# "
  e.delete('TM_COMMENT_END')
  e['TM_COMMENT_START_2'] = "=begin\n"
  e['TM_COMMENT_END_2'] = "=end\n"
end