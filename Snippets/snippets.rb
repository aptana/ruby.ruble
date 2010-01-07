snippet '#!/usr/bin/env ruby -wKU' do |s|
  s.trigger = 'rb'
  s.expansion = '#!/usr/bin/env ruby${TM_RUBY_SWITCHES: -wKU}
'
end

snippet ':yields:' do |s|
  s.trigger = 'y'
  s.expansion = ' :yields: ${0:arguments}'
end

snippet 'if É else É end' do |s|
  s.trigger = 'ife'
  s.expansion = 'if ${1:condition}
	$2
else
	$3
end'
end

snippet 'if É end' do |s|
  s.trigger = 'if'
  s.expansion = 'if ${1:condition}
	$0
end'
end

snippet 'case É end' do |s|
  s.trigger = 'case'
  s.expansion = 'case ${1:object}
when ${2:condition}
	$0
end'
end

snippet '__END__' do |s|
  s.trigger = 'end'
  s.expansion = '__END__
'
end

snippet 'Add Ô# =>Õ Marker' do |s|
  s.trigger = '#'
  s.expansion = '# => '
end

snippet 'alias_method ..' do |s|
  s.trigger = 'am'
  s.expansion = 'alias_method :${1:new_name}, :${0:old_name}'
end

snippet 'all? { |e| .. }' do |s|
  s.trigger = 'all'
  s.expansion = 'all? { |${1:e}| $0 }'
end

snippet 'any? { |e| .. }' do |s|
  s.trigger = 'any'
  s.expansion = 'any? { |${1:e}| $0 }'
end

snippet 'application { .. }' do |s|
  s.trigger = 'app'
  s.expansion = 'if __FILE__ == \$PROGRAM_NAME
	$0
end'
end

snippet 'Array.new(10) { |i| .. }' do |s|
  s.trigger = 'Array'
  s.expansion = 'Array.new(${1:10}) { ${2/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:|)/}${2:i}${2/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:| )/}$0 }'
end

snippet 'assert(..)' do |s|
  s.trigger = 'as'
  s.expansion = 'assert`snippet_paren.rb`${1:test}, "${0:Failure message.}"`snippet_paren.rb end`'
end

snippet 'assert_equal(..)' do |s|
  s.trigger = 'ase'
  s.expansion = 'assert_equal`snippet_paren.rb`${1:expected}, ${0:actual}`snippet_paren.rb end`'
end

snippet 'assert_in_delta(..)' do |s|
  s.trigger = 'asid'
  s.expansion = 'assert_in_delta`snippet_paren.rb`${1:expected_float}, ${2:actual_float}, ${0:2 ** -20}`snippet_paren.rb end`'
end

snippet 'assert_instance_of(..)' do |s|
  s.trigger = 'asio'
  s.expansion = 'assert_instance_of`snippet_paren.rb`${1:ExpectedClass}, ${0:actual_instance}`snippet_paren.rb end`'
end

snippet 'assert_kind_of(..)' do |s|
  s.trigger = 'asko'
  s.expansion = 'assert_kind_of`snippet_paren.rb`${1:ExpectedKind}, ${0:actual_instance}`snippet_paren.rb end`'
end

snippet 'assert_match(..)' do |s|
  s.trigger = 'asm'
  s.expansion = 'assert_match`snippet_paren.rb`/${1:expected_pattern}/, ${0:actual_string}`snippet_paren.rb end`'
end

snippet 'assert_nil(..)' do |s|
  s.trigger = 'asn'
  s.expansion = 'assert_nil`snippet_paren.rb`${0:instance}`snippet_paren.rb end`'
end

snippet 'assert_no_match(..)' do |s|
  s.trigger = 'asnm'
  s.expansion = 'assert_no_match`snippet_paren.rb`/${1:unexpected_pattern}/, ${0:actual_string}`snippet_paren.rb end`'
end

snippet 'assert_not_equal(..)' do |s|
  s.trigger = 'asne'
  s.expansion = 'assert_not_equal`snippet_paren.rb`${1:unexpected}, ${0:actual}`snippet_paren.rb end`'
end

snippet 'assert_not_nil(..)' do |s|
  s.trigger = 'asnn'
  s.expansion = 'assert_not_nil`snippet_paren.rb`${0:instance}`snippet_paren.rb end`'
end

snippet 'assert_not_same(..)' do |s|
  s.trigger = 'asns'
  s.expansion = 'assert_not_same`snippet_paren.rb`${1:unexpected}, ${0:actual}`snippet_paren.rb end`'
end

snippet 'assert_nothing_raised(..) { .. }' do |s|
  s.trigger = 'asnr'
  s.expansion = 'assert_nothing_raised(${1:Exception}) { $0 }'
end

snippet 'assert_nothing_thrown { .. }' do |s|
  s.trigger = 'asnt'
  s.expansion = 'assert_nothing_thrown { $0 }'
end

snippet 'assert_operator(..)' do |s|
  s.trigger = 'aso'
  s.expansion = 'assert_operator`snippet_paren.rb`${1:left}, :${2:operator}, ${0:right}`snippet_paren.rb end`'
end

snippet 'assert_raise(..) { .. }' do |s|
  s.trigger = 'asr'
  s.expansion = 'assert_raise(${1:Exception}) { $0 }'
end

snippet 'assert_respond_to(..)' do |s|
  s.trigger = 'asrt'
  s.expansion = 'assert_respond_to`snippet_paren.rb`${1:object}, :${0:method}`snippet_paren.rb end`'
end

snippet 'assert_same(..)' do |s|
  s.trigger = 'ass'
  s.expansion = 'assert_same`snippet_paren.rb`${1:expected}, ${0:actual}`snippet_paren.rb end`'
end

snippet 'assert_send(..)' do |s|
  s.trigger = 'ass'
  s.expansion = 'assert_send`snippet_paren.rb`[${1:object}, :${2:message}, ${0:args}]`snippet_paren.rb end`'
end

snippet 'assert_throws(..) { .. }' do |s|
  s.trigger = 'ast'
  s.expansion = 'assert_throws(:${1:expected}) { $0 }'
end

snippet 'attr_accessor ..' do |s|
  s.trigger = 'rw'
  s.expansion = 'attr_accessor :${0:attr_names}'
end

snippet 'attr_reader ..' do |s|
  s.trigger = 'r'
  s.expansion = 'attr_reader :${0:attr_names}'
end

snippet 'attr_writer ..' do |s|
  s.trigger = 'w'
  s.expansion = 'attr_writer :${0:attr_names}'
end

snippet 'Benchmark.bmbm do .. end' do |s|
  s.trigger = 'bm-'
  s.expansion = 'TESTS = ${1:10_000}
Benchmark.bmbm do |results|
  $0
end'
end

snippet 'class .. < DelegateClass .. initialize .. end' do |s|
  s.trigger = 'cla-'
  s.expansion = 'class ${1:${TM_FILENAME/(?:\A|_)([A-Za-z0-9]+)(?:\.rb)?/(?2::\u$1)/g}} < DelegateClass(${2:ParentClass})
	def initialize${3/(^.*?\S.*)|.*/(?1:\()/}${3:args}${3/(^.*?\S.*)|.*/(?1:\))/}
		super(${4:del_obj})
		
		$0
	end
	
	
end'
end

snippet 'class .. < ParentClass .. initialize .. end' do |s|
  s.trigger = 'cla'
  s.expansion = 'class ${1:${TM_FILENAME/(?:\A|_)([A-Za-z0-9]+)(?:\.rb)?/(?2::\u$1)/g}} < ${2:ParentClass}
	def initialize${3/(^.*?\S.*)|.*/(?1:\()/}${3:args}${3/(^.*?\S.*)|.*/(?1:\))/}
		$0
	end
	
	
end'
end

snippet 'ClassName = Struct .. do .. end' do |s|
  s.trigger = 'cla'
  s.expansion = '${1:${TM_FILENAME/(?:\A|_)([A-Za-z0-9]+)(?:\.rb)?/(?2::\u$1)/g}} = Struct.new(:${2:attr_names}) do
	def ${3:method_name}
		$0
	end
	
	
end'
end

snippet 'class .. < Test::Unit::TestCase .. end' do |s|
  s.trigger = 'tc'
  s.expansion = 'require "test/unit"

require "${1:library_file_name}"

class Test${2:${1/([\w&&[^_]]+)|./\u$1/g}} < Test::Unit::TestCase
	def test_${3:case_name}
		$0
	end
end'
end

snippet 'class .. end' do |s|
  s.trigger = 'cla'
  s.expansion = 'class ${1:${TM_FILENAME/(?:\A|_)([A-Za-z0-9]+)(?:\.rb)?/(?2::\u$1)/g}}
	$0
end'
end

snippet 'class .. initialize .. end' do |s|
  s.trigger = 'cla'
  s.expansion = 'class ${1:${TM_FILENAME/(?:\A|_)([A-Za-z0-9]+)(?:\.rb)?/(?2::\u$1)/g}}
	def initialize${2/(^.*?\S.*)|.*/(?1:\()/}${2:args}${2/(^.*?\S.*)|.*/(?1:\))/}
		$0
	end
	
	
end'
end

snippet 'class BlankSlate .. initialize .. end' do |s|
  s.trigger = 'cla'
  s.expansion = 'class ${1:BlankSlate}
	instance_methods.each { |meth| undef_method(meth) unless meth =~ /\A__/ }
	
	def initialize${2/(^.*?\S.*)|.*/(?1:\()/}${2:args}${2/(^.*?\S.*)|.*/(?1:\))/}
		@${3:delegate} = ${4:delegate_object}
		
		$0
	end
	
	def method_missing(meth, *args, &block)
		@${3:delegate}.send(meth, *args, &block)
	end
	
	
end'
end

snippet 'class << self .. end' do |s|
  s.trigger = 'cla'
  s.expansion = 'class << ${1:self}
	$0
end'
end

snippet 'class_from_name()' do |s|
  s.trigger = 'clafn'
  s.expansion = 'split("::").inject(Object) { |par, const| par.const_get(const) }'
end

snippet 'classify { |e| .. }' do |s|
  s.trigger = 'cl'
  s.expansion = 'classify { |${1:e}| $0 }'
end

snippet 'collect { |e| .. }' do |s|
  s.trigger = 'col'
  s.expansion = 'collect { |${1:e}| $0 }'
end

snippet 'deep_copy(..)' do |s|
  s.trigger = 'deec'
  s.expansion = 'Marshal.load(Marshal.dump(${0:obj_to_copy}))'
end

snippet 'def É end' do |s|
  s.trigger = 'def'
  s.expansion = 'def ${1:method_name}
	$0
end'
end

snippet 'def method_missing .. end' do |s|
  s.trigger = 'defmm'
  s.expansion = 'def method_missing(meth, *args, &blk)
	$0
end'
end

snippet 'def self .. end' do |s|
  s.trigger = 'defs'
  s.expansion = 'def self.${1:class_method_name}
	$0
end'
end

snippet 'def test_ .. end' do |s|
  s.trigger = 'deft'
  s.expansion = 'def test_${1:case_name}
	$0
end'
end

snippet 'def_delegator ..' do |s|
  s.trigger = 'defd'
  s.expansion = 'def_delegator :${1:@del_obj}, :${2:del_meth}, :${3:new_name}'
end

snippet 'def_delegators ..' do |s|
  s.trigger = 'defds'
  s.expansion = 'def_delegators :${1:@del_obj}, :${0:del_methods}'
end

snippet 'delete_if { |e| .. }' do |s|
  s.trigger = 'deli'
  s.expansion = 'delete_if { |${1:e}| $0 }'
end

snippet 'detect { |e| .. }' do |s|
  s.trigger = 'det'
  s.expansion = 'detect { |${1:e}| $0 }'
end

snippet 'Dir.glob("..") { |file| .. }' do |s|
  s.trigger = 'Dir'
  s.expansion = 'Dir.glob(${1:"${2:dir/glob/*}"}) { |${3:file}| $0 }'
end

snippet 'Dir[".."]' do |s|
  s.trigger = 'Dir'
  s.expansion = 'Dir[${1:"${2:glob/**/*.rb}"}]'
end

snippet 'directory()' do |s|
  s.trigger = 'dir'
  s.expansion = 'File.dirname(__FILE__)'
end

snippet 'Insert do |variable| É end' do |s|
  s.trigger = 'do'
  s.expansion = 'do${1/(^(?<var>\s*[a-z_][a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1: |)/}${1:variable}${1/(^(?<var>\s*[a-z_][a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:|)/}
	$0
end'
end

snippet 'downto(0) { |n| .. }' do |s|
  s.trigger = 'dow'
  s.expansion = 'downto(${1:0}) { ${2/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:|)/}${2:n}${2/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:| )/}$0 }'
end

snippet 'each { |e| .. }' do |s|
  s.trigger = 'ea'
  s.expansion = 'each { |${1:e}| $0 }'
end

snippet 'each_byte { |byte| .. }' do |s|
  s.trigger = 'eab'
  s.expansion = 'each_byte { |${1:byte}| $0 }'
end

snippet 'each_index { |i| .. }' do |s|
  s.trigger = 'eai'
  s.expansion = 'each_index { |${1:i}| $0 }'
end

snippet 'each_key { |key| .. }' do |s|
  s.trigger = 'eak'
  s.expansion = 'each_key { |${1:key}| $0 }'
end

snippet 'each_line { |line| .. }' do |s|
  s.trigger = 'eal'
  s.expansion = 'each_line$1 { |${2:line}| $0 }'
end

snippet 'each_pair { |name, val| .. }' do |s|
  s.trigger = 'eap'
  s.expansion = 'each_pair { |${1:name}, ${2:val}| $0 }'
end

snippet 'each_slice(..) { |group| .. }' do |s|
  s.trigger = 'eas-'
  s.expansion = 'each_slice(${1:2}) { |${2:group}| $0 }'
end

snippet 'each_value { |val| .. }' do |s|
  s.trigger = 'eav'
  s.expansion = 'each_value { |${1:val}| $0 }'
end

snippet 'each_with_index { |e, i| .. }' do |s|
  s.trigger = 'eawi'
  s.expansion = 'each_with_index { |${1:e}, ${2:i}| $0 }'
end

snippet 'elsif ...' do |s|
  s.trigger = 'elsif'
  s.expansion = 'elsif ${1:condition}
	$0'
end

# FIXME No tab trigger, probably needs to become command
snippet 'Embedded Code Ñ #{É}' do |s|
  s.expansion = '#{${1:$TM_SELECTED_TEXT}}'
end

snippet 'fetch(name) { |key| .. }' do |s|
  s.trigger = 'fet'
  s.expansion = 'fetch(${1:name}) { ${2/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:|)/}${2:key}${2/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:| )/}$0 }'
end

snippet 'File.foreach ("..") { |line| .. }' do |s|
  s.trigger = 'File'
  s.expansion = 'File.foreach(${1:"${2:path/to/file}"}) { |${3:line}| $0 }'
end

snippet 'File.open("..") { |file| .. }' do |s|
  s.trigger = 'File'
  s.expansion = 'File.open(${1:"${2:path/to/file}"}${3/(^[rwab+]+$)|.*/(?1:, ")/}${3:w}${3/(^[rwab+]+$)|.*/(?1:")/}) { |${4:file}| $0 }'
end

snippet 'File.read("..")' do |s|
  s.trigger = 'File'
  s.expansion = 'File.read(${1:"${2:path/to/file}"})'
end

snippet 'fill(range) { |i| .. }' do |s|
  s.trigger = 'fil'
  s.expansion = 'fill(${1:range}) { ${2/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:|)/}${2:i}${2/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:| )/}$0 }'
end

snippet 'find { |e| .. }' do |s|
  s.trigger = 'fin'
  s.expansion = 'find { |${1:e}| $0 }'
end

snippet 'find_all { |e| .. }' do |s|
  s.trigger = 'fina'
  s.expansion = 'find_all { |${1:e}| $0 }'
end

snippet 'flatten_once()' do |s|
  s.trigger = 'flao'
  s.expansion = 'inject(Array.new) { |${1:arr}, ${2:a}| ${1:arr}.push(*${2:a}) }'
end

snippet 'flunk(..)' do |s|
  s.trigger = 'fl'
  s.expansion = 'flunk`snippet_paren.rb`"${0:Failure message.}"`snippet_paren.rb end`'
end

snippet 'grep(/pattern/) { |match| .. }' do |s|
  s.trigger = 'gre'
  s.expansion = 'grep(${1:/${2:pattern}/}) { |${3:match}| $0 }'
end

snippet 'gsub(/../) { |match| .. }' do |s|
  s.trigger = 'gsu'
  s.expansion = 'gsub(/${1:pattern}/) { ${2/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:|)/}${2:match}${2/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:| )/}$0 }'
end

snippet 'Hash Pair Ñ :key => "value"' do |s|
  s.trigger = ':'
  s.expansion = ':${1:key} => ${2:"${3:value}"}${4:, }'
end

snippet 'Hash.new { |hash, key| hash[key] = .. }' do |s|
  s.trigger = 'Hash'
  s.expansion = 'Hash.new { |${1:hash}, ${2:key}| ${1:hash}[${2:key}] = $0 }'
end

snippet 'include Comparable ..' do |s|
  s.trigger = 'Comp'
  s.expansion = 'include Comparable

def <=>(other)
	$0
end'
end

snippet 'include Enumerable ..' do |s|
  s.trigger = 'Enum'
  s.expansion = 'include Enumerable

def each(&block)
	$0
end'
end

snippet 'inject(init) { |mem, var| .. }' do |s|
  s.trigger = 'inj'
  s.expansion = 'inject${1/.+/(/}${1:init}${1/.+/)/} { |${2:mem}, ${3:var}| $0 }'
end

snippet 'lambda { |args| .. }' do |s|
  s.trigger = 'lam'
  s.expansion = 'lambda { ${1/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:|)/}${1:args}${1/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:| )/}$0 }'
end

snippet 'loop { .. }' do |s|
  s.trigger = 'loo'
  s.expansion = 'loop { $0 }'
end

snippet 'map { |e| .. }' do |s|
  s.trigger = 'map'
  s.expansion = 'map { |${1:e}| $0 }'
end

snippet 'Marshal.dump(.., file)' do |s|
  s.trigger = 'Md'
  s.expansion = 'File.open(${1:"${2:path/to/file}.dump"}, "wb") { |${3:file}| Marshal.dump(${4:obj}, ${3:file}) }'
end

snippet 'Marshal.load(obj)' do |s|
  s.trigger = 'Ml'
  s.expansion = 'File.open(${1:"${2:path/to/file}.dump"}, "rb") { |${3:file}| Marshal.load(${3:file}) }'
end

snippet 'max { |a, b| .. }' do |s|
  s.trigger = 'max'
  s.expansion = 'max { |a, b| $0 }'
end

snippet 'min { |a, b| .. }' do |s|
  s.trigger = 'min'
  s.expansion = 'min { |a, b| $0 }'
end

snippet 'module .. ClassMethods .. end' do |s|
  s.trigger = 'mod'
  s.expansion = 'module ${1:${TM_FILENAME/(?:\A|_)([A-Za-z0-9]+)(?:\.rb)?/(?2::\u$1)/g}}
	module ClassMethods
		$0
	end
	
	module InstanceMethods
		
	end
	
	def self.included(receiver)
		receiver.extend         ClassMethods
		receiver.send :include, InstanceMethods
	end
end'
end

snippet 'module .. end' do |s|
  s.trigger = 'mod'
  s.expansion = 'module ${1:${TM_FILENAME/(?:\A|_)([A-Za-z0-9]+)(?:\.rb)?/(?2::\u$1)/g}}
	$0
end'
end

snippet 'module .. module_function .. end' do |s|
  s.trigger = 'mod'
  s.expansion = 'module ${1:${TM_FILENAME/(?:\A|_)([A-Za-z0-9]+)(?:\.rb)?/(?2::\u$1)/g}}
	module_function
	
	$0
end'
end

snippet 'namespace :.. do .. end' do |s|
  s.trigger = 'nam'
  s.expansion = 'namespace :${1:${TM_FILENAME/\.\w+//}} do
	$0
end'
end

snippet 'Insert { |variable| É }' do |s|
  s.trigger = '{'
  s.expansion = '{ ${1/(^(?<var>\s*[a-z_][a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:|)/}${1:variable}${1/(^(?<var>\s*[a-z_][a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:| )/}${2:$TM_SELECTED_TEXT} '
end

snippet 'open("path/or/url", "w") { |io| .. }' do |s|
  s.trigger = 'ope'
  s.expansion = 'open(${1:"${2:path/or/url/or/pipe}"}${3/(^[rwab+]+$)|.*/(?1:, ")/}${3:w}${3/(^[rwab+]+$)|.*/(?1:")/}) { |${4:io}| $0 }'
end

snippet 'option_parse { .. }' do |s|
  s.trigger = 'optp'
  s.expansion = 'require "optparse"

options = {${1::default => "args"}}

ARGV.options do |opts|
	opts.banner = "Usage:  #{File.basename(\$PROGRAM_NAME)} [OPTIONS]${2/^\s*$|(.*\S.*)/(?1: )/}${2:OTHER_ARGS}"
	
	opts.separator ""
	opts.separator "Specific Options:"
	
	$0
	
	opts.separator "Common Options:"
	
	opts.on( "-h", "--help",
	         "Show this message." ) do
		puts opts
		exit
	end
	
	begin
		opts.parse!
	rescue
		puts opts
		exit
	end
end
'
end

snippet 'partition { |e| .. }' do |s|
  s.trigger = 'par'
  s.expansion = 'partition { |${1:e}| $0 }'
end

snippet 'path_from_here( .. )' do |s|
  s.trigger = 'patfh'
  s.expansion = 'File.join(File.dirname(__FILE__), *%w[${1:rel path here}])'
end

snippet 'PStore.new( .. )' do |s|
  s.trigger = 'Pn-'
  s.expansion = 'PStore.new(${1:"${2:file_name.pstore}"})'
end

snippet 'randomize()' do |s|
  s.trigger = 'ran'
  s.expansion = 'sort_by { rand }'
end

snippet 'New Block' do |s|
  s.trigger = '=b'
  s.expansion = '`[[ $TM_LINE_INDEX != 0 ]] && echo; echo`=begin rdoc
	$0
=end'
end

snippet 'reject { |e| .. }' do |s|
  s.trigger = 'rej'
  s.expansion = 'reject { |${1:e}| $0 }'
end

snippet 'require ".."' do |s|
  s.trigger = 'req'
  s.expansion = 'require "$0"'
end

snippet 'require "tc_.." ..' do |s|
  s.trigger = 'ts'
  s.expansion = 'require "test/unit"

require "tc_${1:test_case_file}"
require "tc_${2:test_case_file}"
'
end

snippet 'require_gem ".."' do |s|
  s.trigger = 'reqg-'
  s.expansion = 'require "$0"'
end

snippet 'results.report(..) { .. }' do |s|
  s.trigger = 'rep'
  s.expansion = 'results.report("${1:name}:") { TESTS.times { $0 } }'
end

snippet 'reverse_each { |e| .. }' do |s|
  s.trigger = 'reve'
  s.expansion = 'reverse_each { |${1:e}| $0 }'
end

snippet 'scan(/../) { |match| .. }' do |s|
  s.trigger = 'sca'
  s.expansion = 'scan(/${1:pattern}/) { |${2:match}| $0 }'
end

snippet 'select { |e| .. }' do |s|
  s.trigger = 'sel'
  s.expansion = 'select { |${1:e}| $0 }'
end

snippet 'singleton_class()' do |s|
  s.trigger = 'sinc'
  s.expansion = 'class << self; self end'
end

snippet 'sort { |a, b| .. }' do |s|
  s.trigger = 'sor'
  s.expansion = 'sort { |a, b| $0 }'
end

snippet 'sort_by { |e| .. }' do |s|
  s.trigger = 'sorb'
  s.expansion = 'sort_by { |${1:e}| $0 }'
end

snippet 'step(2) { |e| .. }' do |s|
  s.trigger = 'ste'
  s.expansion = 'step(${1:2}) { ${2/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:|)/}${2:n}${2/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:| )/}$0 }'
end

snippet 'sub(/../) { |match| .. }' do |s|
  s.trigger = 'sub'
  s.expansion = 'sub(/${1:pattern}/) { ${2/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:|)/}${2:match}${2/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:| )/}$0 }'
end

snippet 'task :task_name => [:dependent, :tasks] do .. end' do |s|
  s.trigger = 'tas'
  s.expansion = 'desc "${1:Task description}"
task :${2:${3:task_name} => ${4:[:${5:dependent, :tasks}]}} do
	$0
end'
end

snippet 'times { |n| .. }' do |s|
  s.trigger = 'tim'
  s.expansion = 'times { ${1/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:|)/}${1:n}${1/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:| )/}$0 }'
end

snippet 'transaction( .. ) { .. }' do |s|
  s.trigger = 'tra'
  s.expansion = 'transaction${1/(^.*?\S.*)|.*/(?1:\()/}${1:true}${1/(^.*?\S.*)|.*/(?1:\))/} { $0 }'
end

snippet 'unix_filter { .. }' do |s|
  s.trigger = 'unif'
  s.expansion = 'ARGF.each_line$1 do |${2:line}|
	$0
end'
end

snippet 'unless ... end' do |s|
  s.trigger = 'unless'
  s.expansion = 'unless ${1:condition}
	$0
end'
end

snippet 'until ... end' do |s|
  s.trigger = 'until'
  s.expansion = 'until ${1:condition}
	$0
end'
end

snippet 'option(..)' do |s|
  s.trigger = 'opt'
  s.expansion = 'opts.on( "-${1:o}", "--${2:long-option-name}"${3/^\s*$|(.*\S.*)/(?1:, )/}${3:String},
         "${4:Option description.}" ) do |${6:opt}|
	$0
end'
end

snippet 'upto(1.0/0.0) { |n| .. }' do |s|
  s.trigger = 'upt'
  s.expansion = 'upto(${1:1.0/0.0}) { ${2/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:|)/}${2:n}${2/(^(?<var>\s*(?:\*|\*?[a-z_])[a-zA-Z0-9_]*\s*)(,\g<var>)*,?\s*$)|.*/(?1:| )/}$0 }'
end

snippet 'usage_if()' do |s|
  s.trigger = 'usai'
  s.expansion = 'if ARGV.$1
	abort "Usage:  #{\$PROGRAM_NAME} ${2:ARGS_GO_HERE}"
end'
end

snippet 'usage_unless()' do |s|
  s.trigger = 'usau'
  s.expansion = 'unless ARGV.$1
	abort "Usage:  #{\$PROGRAM_NAME} ${2:ARGS_GO_HERE}"
end'
end

snippet 'when ...' do |s|
  s.trigger = 'when'
  s.expansion = 'when ${1:condition}
	$0'
end

snippet 'while ... end' do |s|
  s.trigger = 'while'
  s.expansion = 'while ${1:condition}
	$0
end'
end

snippet 'begin ... rescue ... end' do |s|
  s.trigger = 'begin'
  s.expansion = '${TM_SELECTED_TEXT/([\t ]*).*/$1/m}begin
	${3:${TM_SELECTED_TEXT/(\A.*)|(.+)|\n\z/(?1:$0:(?2:\t$0))/g}}
${TM_SELECTED_TEXT/([\t ]*).*/$1/m}rescue ${1:Exception}${2/.+/ => /}${2:e}
${TM_SELECTED_TEXT/([\t ]*).*/$1/m}	$0
${TM_SELECTED_TEXT/([\t ]*).*/$1/m}end
'
end

snippet 'xmlread(..)' do |s|
  s.trigger = 'xml-'
  s.expansion = 'REXML::Document.new(File.read(${1:"${2:path/to/file}"}))'
end

snippet 'xpath(..) { .. }' do |s|
  s.trigger = 'xpa'
  s.expansion = 'elements.each(${1:"${2://XPath}"}) do |${3:node}|
	$0
end'
end

snippet 'zip(enums) { |row| .. }' do |s|
  s.trigger = 'zip'
  s.expansion = 'zip(${1:enums}) { |${2:row}| $0 }'
end

