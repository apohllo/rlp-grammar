# encoding: utf-8
$:.unshift "lib"
require 'rlp'
require 'rspec/expectations'

Before do
  unless Rlp::Client.instance.opened?
    Rlp::Client.instance.open_database("tmp/rlp-grammar")
  end
end

################################################################
# Given
################################################################

Given /^że kodowanie ustawione jest na '([^']+)'$/ do |encoding|
  Rlp::Client.instance.encoding = 'utf-8'
end

