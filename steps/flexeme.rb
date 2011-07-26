# encoding: utf-8
$:.unshift "steps"
require 'init'
require 'utils'


################################################################
# When
################################################################

# Jeżeli w słowniku jest forma 'profesor'
When /^w słowniku jest forma '([^']+)'$/ do |form|
  @form = form
end

When /^szukam dla niej fleksemów$/ do
  @flexemes = Rlp::Grammar::Flexeme.find(@form)
end

# Jeżeli w słowniku jest fleksem typu 'rzeczownik'
When /^w słowniku jest fleksem typu '([^']+)'$/ do |name|
  klass = Rlp::Grammar::FlexemeType.for_name(name).to_class
  @flexeme = klass.each{|f| break f}
  raise "Flexeme type doesn't have forms: #{name}" if @flexeme == 0
end

# Jeżelie w słowniku występuje type fleksemu 'rzeczownik'
When /^w słowniku występuje typ fleksemu '([^']*)'/ do |name|
  @item = Rlp::Grammar::FlexemeType.for_name(name)
end

################################################################
# Then
################################################################

# Wtedy znajduję fleksem typu 'rzeczownik'
Then /^znajduję fleksem typu '([^']+)'$/ do |type|
  @flexemes.any?{|f| f.type.name == type}.should == true
end

# Wtedy posiada on ustalony rodzaj
Then /^posiada on ustalon(?:y|ą) ([[:lower:]]+)$/ do |name|
  category = get_category(name)
  @flexeme.has?(category).should == true
  @flexeme.send(category).should_not == nil
end

# Wtedy odmienia się przez przypadki
Then /^odmienia się przez ([[:lower:]]+)$/ do |name|
  category = get_category(name)
  @flexeme.inflects_for?(category).should == true
  @flexeme.positions(category).each do |position|
    @flexeme.inflect(category => position).should_not == nil
  end
end

# Wtedy posiada on 7 pozycji fleksyjnych
Then /^posiada (\d+) pozycj(?:ę|i|e) fleksyjn(?:ą|ych|e)/ do |count|
  @flexeme.positions.size.should == count.to_i
end

# Wtedy jest on nieodmienny
Then /^jest on nieodmienny$/ do
  @flexeme.positions.size.should == 1
end

# Wtedy posiada liczbę mnogą
Then /^posiada ([^o][[:lower:]]+) ([[:lower:]].+)$/ do |category,value|
  category = get_category(category)
  value = get_value(value)
  @flexeme.send(category).should == value
end

Then /^odmienia się przez przypadki: (.*)$/ do |cases|
  cases = cases.split(/(,| i )\s+/).map{|c| Rlp::Grammar::Value.for_name(c).tag}
  category = get_category("przypadki")
  @flexeme.inflects_for?(category).should == true
  @flexeme.positions(category).size.should == cases.size
  cases.each do |kase|
    @flexeme.positions(category).include?(kase).should == true
  end
end

Then /^rządzi on określonymi przypadkami$/ do
  @flexeme.governance.size.should > 0
  @flexeme.governance.each{|g| g[:case].should_not == nil}
end
