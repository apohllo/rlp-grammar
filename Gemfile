source "http://rubygems.org"

# Specify your gem's dependencies in rlp.gemspec
gemspec
#gem 'rlp', "0.3.8"
gem 'colors'
if ENV['production']
  gem 'rod', :git => 'git://github.com/apohllo/rod.git', :branch => 'v0.7.x'
else
  gem 'rod', :path => '/home/fox/src/nlp/wsd/rod/'
  gem 'ruby-debug19'
  gem 'ruby-debug-base19'
  #gem "ruby-prof"
end
