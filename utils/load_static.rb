#!/bin/env ruby
# encoding: utf-8

$:.unshift "lib"
require 'rlp'
require 'rod'
require 'pp'


def parse_table(line)
  line.split("|")[1..-2].map{|e| e.strip}
end

def parse_feature(file_name,elements)
  File.open(file_name) do |file|
    # states:
    # :start - look for 'Szablon scenariusza'
    # :template - 'Szablon scenariusza', look for table
    # :table - table, parse if table, move to 1 if 'Szablon scenariusza'
    state = :start
    type = nil
    names = nil
    file.each do |line|
      next if line =~ /^\s*#/
      next if line =~ /^\s*$/
      case state
      when :start
        if line =~ /Szablon scenariusza:(.+)$/
          state = :template
          type = $1.strip
          elements[type] = {}
        end
      when :template
        if line =~ /^\s+\|/
          state = :table
          names = parse_table(line)
          elements[type][:names] = names
        end
      when :table
        if line =~ /Szablon scenariusza:(.+)$/
          state = :start
          redo
        end
        elements[type][:values] ||= []
        fields = parse_table(line)
        elements[type][:values] << fields
      end
    end
  end
end

ELEMENTS = {}

parse_feature("polish-spec/kategorie/typy.feature",ELEMENTS)
parse_feature("polish-spec/kategorie/wartosci.feature",ELEMENTS)

CATEGORIES = ELEMENTS.delete("kategorie gramatyczne")[:values]
#pp CATEGORIES

FLEXEME_TYPES = ELEMENTS.delete("typy fleksemów")[:values]

VALUES = []
ELEMENTS.values.map{|e| e[:values]}.each{|e| e.each{|v| VALUES << v}}
#pp VALUES

File.open("data/types_to_classes.txt") do |file|
  file.each do |line|
    tag,klass = line.split(/\s+/)
    type = FLEXEME_TYPES.find{|t| t[-1] == tag}
    type << klass
  end
end
#pp FLEXEME_TYPES


FileUtils.mkdir("tmp") if !File.exist?("tmp")
Rlp::StaticDatabase.instance.create_database("tmp/static.dat")

FLEXEME_TYPES.each do |name,tag,klass|
  type = Rlp::FlexemeType.new
  type.name = name
  type.tag = tag.to_sym
  type.class_name = klass
  type.store
end

@cats = {}
CATEGORIES.each do |name,tag|
  category = Rlp::GrammaticalCategory.new
  category.tag = tag.to_sym
  category.name = name
  @cats[name] = category
end
VALUES.each do |name, cat_name, tag|
  value = Rlp::Value.new
  value.name = name
  value.tag = tag.to_sym
  value.category = @cats[cat_name]
  @cats[cat_name].values << value
  value.store
end

@cats.each{|k,v| v.store}

Rlp::StaticDatabase.instance.close_database
