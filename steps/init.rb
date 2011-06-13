# encoding: utf-8
$:.unshift "lib"
require 'rlp/grammar'
require 'rspec/expectations'

Before do
  unless Rlp::Grammar::Client.instance.opened?
    Rlp::Grammar::Client.instance.open_database("tmp/rlp-grammar")
  end
end

################################################################
# Given
################################################################

Given /^że kodowanie ustawione jest na '([^']+)'$/ do |encoding|
  Rlp::Grammar::Client.instance.encoding = 'utf-8'
end

