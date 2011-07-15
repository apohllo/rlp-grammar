# encoding: utf-8
$:.unshift "steps"
require 'init'

################################################################
# When
################################################################
When /^w słowniku występuje wartość kategorii gramatycznej '([^']+)'$/ do |name|
  @item = Rlp::Grammar::Value.for_name(name)
end

When /^w słowniku występuje kategoria gramatycza '([^']+)'$/ do |name|
  @item = Rlp::Grammar::Category.for_name(name)
end


################################################################
# Then
################################################################
Then /^należy ona do kategorii gramatycznej '([^']*)'$/ do |name|
  Rlp::Grammar::Category.for_name(name).values.include?(@item)
end

Then /^posiada on(a)? oznaczenie '(\w+)'$/ do |ignore,name|
  @item.tag.should == name.to_sym
end

