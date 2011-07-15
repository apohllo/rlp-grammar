# encoding: utf-8
require 'bundler'

include Rake::DSL
Bundler::GemHelper.install_tasks

task "cucu" do
  sh "bundle exec cucumber -r steps/category.rb -r steps/flexeme.rb polish-spec/kategorie"
  sh "bundle exec cucumber -r steps/category.rb -r steps/flexeme.rb polish-spec/fleksemy/typy.feature"
  sh "bundle exec cucumber -r steps/category.rb -r steps/flexeme.rb polish-spec/fleksemy/cechy-morfosyntaktyczne.feature"
end

task "init" do
  sh "bundle exec ruby utils/load_static.rb"
  sh "bundle exec ruby utils/suffixes.rb"
  sh "rm -rf tmp/rlp-grammar.init"
  sh "cp -r tmp/rlp-grammar tmp/rlp-grammar.init"
end

task "load" do
  sh "rm -rf tmp/rlp-grammar"
  sh "cp -r tmp/rlp-grammar.init tmp/rlp-grammar"
  sh "bundle exec ruby utils/load_forms2.rb data/sgjp.txt 100_000"
  #sh "bundle exec ruby utils/load_forms2.rb data/morfologik.txt 10_000"
  sh "bundle exec ruby utils/load_forms2.rb 10_000"
end

task "check" do
  sh "bundle exec ruby work/check_form.rb abakan"
  sh "bundle exec ruby work/check_form.rb abdykował"
  sh "bundle exec ruby work/check_form.rb ablaktować"
  sh "bundle exec ruby work/check_form.rb aaronowego"
end
