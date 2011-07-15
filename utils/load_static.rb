#!/bin/env ruby
# encoding: utf-8

$:.unshift "lib"
$:.unshift "steps"
require 'rlp/grammar'
require 'rod'
require 'pp'
require 'gherkin'
require 'utils'
require 'yaml'

class ParserListener
  def initialize(scenarios)
    @scenarios = scenarios
  end

  def uri(uri)
  end

  def feature(feature)
  end

  def background(background)
  end

  def scenario(scenario)
    @name = scenario.name.strip
    @scenarios[@name] = {}
    @set = 0
  end

  def scenario_outline(outline)
    @name = outline.name.strip
    @scenarios[@name] = {}
  end

  def examples(examples)
    examples.rows.each.with_index do |row,index|
      if index == 0
        @scenarios[@name][:names] = row.cells
        @scenarios[@name][:values] = []
      else
        @scenarios[@name][:values] << row.cells
      end
    end
  end

  def step(step)
    return if @name.nil?
    return if @set.nil?
    keyword = step.keyword
    if keyword =~ /^I/
      if @last_keyword
        keyword = @last_keyword
      else
        return
      end
    end
    case keyword
    when /^Jeżeli/
      if @last_keyword && @last_keyword != keyword
        @set += 1
      end
      @scenarios[@name][@set] ||= [[],[]]
      @scenarios[@name][@set][0] << step.name
    when /^Wtedy/
      @scenarios[@name][@set][1] << step.name
    end
    @last_keyword = keyword
  end

  def eof
  end
end

def parse_feature(file_name,elements)
  listener = ParserListener.new(elements)
  parser = Gherkin::Parser::Parser.new(listener, true, 'root', false)
  source = File.open(file_name,"r:utf-8").read
  parser.parse(source,file_name,0)
end

values = {}
categories = {}
features = {}

parse_feature("polish-spec/kategorie/typy.feature",categories)
parse_feature("polish-spec/kategorie/wartosci.feature",values)
parse_feature("polish-spec/fleksemy/cechy-morfosyntaktyczne.feature",features)

CATEGORIES = categories.delete("kategorie gramatyczne")[:values]
FLEXEME_TYPES = categories.delete("typy fleksemów")[:values]

VALUES = []
values.values.map{|e| e[:values]}.each{|e| e.each{|v| VALUES << v}}

FEATURES = {}
features.values.each do |group|
  group.values.each do |rule|
    type_rule, features_rule = rule
    type = type_rule.first.match(/typu '([^']+)'$/)[1]
    FEATURES[type] = {}
    FEATURES[type][:inflective] = []
    FEATURES[type][:defective] = []
    FEATURES[type][:rigid] = []
    FEATURES[type][:values] = []
    begin
      features_rule.each do |feature_rule|
        case feature_rule
        when /^odmienia się przez (.*)/
          FEATURES[type][:inflective] << get_category($1)
        when /^jest on stopniowalny/
          FEATURES[type][:inflective] << :degree
        when /^odmienia się defektywnie przez (.*)/
          FEATURES[type][:defective] << get_category($1)
        when /^posiada on (.*)/
          FEATURES[type][:rigid] << get_category($1)
        when /^jest on nieodmienny/
          FEATURES[type][:fixed] = true
          FEATURES[type][:count] = 1
        when /^posiada (\d+) pozycj(?:.) fleks/
          FEATURES[type][:count] = $1.to_i
        when /^posiada (.*)/
          FEATURES[type][:values] << get_value($1)
        else
          puts "Not matched '#{feature_rule}'"
        end
      end
    rescue Exception => ex
      puts ex
    end
  end
end
#pp FEATURES

File.open("data/types_to_classes.txt") do |file|
  file.each do |line|
    tag,klass,inflections = line.split(/\s+/)
    type = FLEXEME_TYPES.find{|t| t[-1] == tag}
    type << "Rlp::Grammar::Flexeme::#{klass}"
    type << inflections
  end
end
#pp FLEXEME_TYPES
PARADIGMS = Hash.new{|h,e| h[e] = []}
File.open("data/paradigms.yml") do |input|
  paradigms = YAML::load(input)
  paradigms.each do |paradigm|
    PARADIGMS[paradigm[:flexeme_type]] << paradigm
  end
end

include Rlp::Grammar

FileUtils.mkdir("tmp") if !File.exist?("tmp")
Client.instance.create_database("tmp/rlp-grammar")

@cats = {}
CATEGORIES.each do |name,tag|
  category = Category.new
  category.tag = tag.to_sym
  category.name = name
  @cats[name] = category
end
VALUES.each do |name, cat_name, tag|
  value = Value.new
  value.name = name
  value.tag = tag.to_sym
  value.category = @cats[cat_name]
  @cats[cat_name].values << value
  value.store
end

@cats.each{|k,v| v.store}

FLEXEME_TYPES.each do |name,tag,klass,inflections|
  type = FlexemeType.new(:name => name, :tag => tag.to_sym,
                         :class_name => klass)
  #p FEATURES[name]
  type.inflective_categories = FEATURES[name][:inflective].
    map{|c| Category.for_tag(c)}
  type.rigid_categories = FEATURES[name][:rigid].
    map{|c| Category.for_tag(c)}
  type.defective_categories = FEATURES[name][:defective].
    map{|c| Category.for_tag(c)}
  type.fixed_values = {}
  combinations = []
  unless inflections.nil?
    inflections.split("|").each do |section|
      set = section.split(",").inject([[]]) do |sum,pair|
        cat,values = pair.split(":")
        result = []
        if values == "_"
          values = Category.for_tag(cat.to_sym).values.map{|v| v.tag.to_s}.join("+")
        end
        values.split("+").each do |comp_value|
          sum.each do |pvalues|
            result << pvalues + [comp_value.to_sym]
          end
        end
        result
      end
      # #1 should store the values in cannonical order
      combinations += set #.map{|vs| type.sort_values(vs)}
    end
  end
  if combinations.size > 0 && FEATURES[name][:count] != combinations.size
    raise "Invalid number #{FEATURES[name][:count]} vs #{combinations.size}"
  end
  type.inflections = combinations
  FEATURES[name][:values].each do |value|
    value = Value.for_tag(value)
    type.fixed_values[value.category.to_sym] = value
  end
  PARADIGMS[type.tag].each do |paradigm_hash|
    gender = paradigm_hash[:gender]
    if gender
      gender = Value.for_tag(gender)
      if gender.rod_id == 0
        gender.store
        gender.category.values << gender
        gender.category.store
      end
    end
    paradigm = Paradigm.new(:suffixes => paradigm_hash[:suffixes],
                            :form_position => paradigm_hash[:form_position],
                            :flexeme_type => type, :gender => gender)
    paradigm.update_code
    paradigm.store
    type.paradigms << paradigm
  end
  type.store
end


Client.instance.close_database
