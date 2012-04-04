# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rlp/grammar/version"

Gem::Specification.new do |s|
  s.name        = "rlp-grammar"
  s.version     = Rlp::Grammar::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Aleksander Pohl"]
  s.email       = ["apohllo@o2.pl"]
  s.homepage    = "http://github.com/apohllo/rlp-grammar"
  s.summary     = %q{A Ruby implementation of the Polish grammar spec}
  s.description = %q{This library is an implementation of the Polish-spec, 
    a specification of inflection and grammatical rules of Polish}

  s.rubyforge_project = "rlp-grammar"
  s.has_rdoc = true
  s.rdoc_options = ["--main", "README.txt"]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  #s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("rod", [">= 0.7.0","< 0.8.0"])
  s.add_dependency("string_case_pl", ["~> 0.1.0"])

  s.add_development_dependency("rspec", ["~> 2.2.0"])
  s.add_development_dependency("cucumber", ["~> 1.0.0"])
end
