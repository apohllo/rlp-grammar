# encoding: utf-8
require File.join(File.dirname(__FILE__),"init")

def get_category(name)
  case name
  when /przypad(ek|ki)/
    :case
  when /rodzaj(e)?/
    :gender
  when /liczb(y|a|ę)/
    :number
  when /osob(ę|y)/
    :person
  when /stop(ień|nie)/
    :degree
  when /aspekt/
    :aspect
  when /akcentowo/
    :accent
  when /poprzyimk/
    :pospre
  when /akomodacyj/
    :accomm
  when /aglutynacyj/
    :agglut
  when /wokaliczno/
    :vocal
  when /kasztowo/
    :lcase
  end
end

################################################################
# When
################################################################

When /^w słowniku jest forma '([^']+)'$/ do |form|
  @form = form
end

When /^szukam dla niej fleksemów$/ do
  @flexemes = Rlp::Flexeme.find(@form)
end

When /^w słowniku jest fleksem typu '([^']+)'$/ do |name|
  klass = Rlp::FlexemeType.for_name(name).to_class
  @flexeme = klass.each{|f| break f}
end

When /^w słowniku występuje typ fleksemu '([^']*)'/ do |name|
  @item = Rlp::FlexemeType.for_name(name)
end

################################################################
# Then
################################################################

Then /^znajduję fleksem typu '([^']+)'$/ do |type|
  @flexemes.any?{|f| f.type.name == type}.should == true
end

Then /^posiada on ustalon(y|ą) ([[:lower:]]+)$/ do |ignore,name|
  category = get_category(name)
  @flexeme.has?(category).should == true
  @flexeme.send(category).should_not == nil
end

Then /^odmienia się przez ([[:lower:]]+)$/ do |name|
  category = get_category(name)
  @flexeme.inflects_for?(category).should == true
end

Then /^posiada (\d+) pozycj(ę|i) fleksyjn(ą|ych)/ do |count,ignore1,ignore2|
  @flexeme.inflections.size.should == count.to_i
end
