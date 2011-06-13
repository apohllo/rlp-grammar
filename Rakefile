require 'bundler'

include Rake::DSL
Bundler::GemHelper.install_tasks

task "cucu" do
  sh "bundle exec cucumber -r steps/category.rb -r steps/flexeme.rb polish-spec/kategorie"
  sh "bundle exec cucumber -r steps/category.rb -r steps/flexeme.rb polish-spec/fleksemy/typy.feature"
  sh "bundle exec cucumber -r steps/category.rb -r steps/flexeme.rb polish-spec/fleksemy/cechy-morfosyntaktyczne.feature"
end
