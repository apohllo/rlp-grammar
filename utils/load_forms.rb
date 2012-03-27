#!/bin/env ruby
# encoding: utf-8

$:.unshift "lib"
require 'rlp/grammar'
require 'string_cmp_pl'
require 'rod'
require 'pp'

#Rlp::Grammar::Client.instance.open_database("tmp/rlp-grammar",:readonly => false)
Rlp::Grammar::Client.instance.open_database("../rlp-corpus/data/rlp",:readonly => false)
TEXT_FORMS = {}

if ARGV.size < 1
  puts "load_forms (forms_count|missing.txt) [data_file.txt]"
  exit
end

if ARGV[0].to_i == 0
  LIMIT = nil
  MISSING_FORMS = {}
  File.readlines(ARGV[0]).map.with_index do |line,index|
    form, type = line.split(" ")[0..1]
    MISSING_FORMS[form] ||= []
    MISSING_FORMS[form] << type
    #break if index == 300
  end
else
  LIMIT = ARGV[0].to_i
  MISSING_FORMS = nil
end

def visit_mappings(tags_to_forms,type,matched,positions=[],forms=[],level=0)
  if level < tags_to_forms.size
    position,position_forms = tags_to_forms[level]
    positions.push position
    position_forms.each do |form|
      forms.push form
      visit_mappings(tags_to_forms,type,matched,positions,forms,level + 1)
      forms.pop
    end
    positions.pop
  else
    #puts "level: #{level}, forms: #{forms}, positions: #{positions}"
    uniq_forms = {}
    forms.zip(positions).each{|f,p| uniq_forms[f] ||= []; uniq_forms[f] << p}
    #p type.tag,uniq_forms.keys,uniq_forms.values
    paradigms = Rlp::Grammar::Paradigm.guess(uniq_forms.keys,type.to_sym,
                                             :tags => uniq_forms.values)
    unless paradigms.empty?
      matched << [paradigms.first,forms.dup,positions.dup]
    end
  end
end

def substitute_type(type)
  tag =
    case type.tag
    when :adja
      :qub
    when :ger
      :subst
    when :xxx
      :qub
    else
      # TODO
      type.tag
    end
  Rlp::Grammar::FlexemeType.for_tag(tag)
end

if ARGV.size == 2
  puts "Reading from #{ARGV[1]}"
  require File.join(".",File.dirname(__FILE__),"sgjp_to_rlp") #if ARGV[1] =~ /sgjp/
  File.open(ARGV[1],"r:iso-8859-2") do |file|
    file.each.with_index do |line,index|
      break if LIMIT && index > LIMIT
      puts index if index % 100000 == 0
      elements = line.encode("utf-8").split(/\s+/)
      tag_groups = Rlp::Utils.map_tags(elements.pop)
      form = elements.shift
      base = elements.join(" ")
      # TODO resolve these issues
      # TODO verb!!! is not in MISSING_FORMS!
      next if tag_groups =~ /^(interj|burk|comp|pred|adjc)/
      #break if index > 100000
      tag_groups.each do |tags|
        #tags = Rlp::Utils.map_tags(tags.split(":"))
        type = tags[0]
        if MISSING_FORMS
          next unless MISSING_FORMS[base] && MISSING_FORMS[base].include?(type)
        end
        # determine gender
        if type =~ /\A(subst|sdef|depr|xxs|ppron3|pronbgen|ger|depr)\Z/
          gender = tags[1..-1].each do |tag|
            begin
              value = Rlp::Grammar::Value.for_tag(tag.to_sym)
              break tag if value.category.tag == :gender
            rescue Rlp::Grammar::RlpException => ex
              # TODO not-ignore
            end
          end
          if gender.is_a?(String)
            type = "#{type}:#{gender}"
          else
            if tags.include?("_")
              type = "#{type}:m1.m2.m3.f.n1.n2.p1.p2.p3"
            else
              raise "Missing gender for type #{type}: #{tags}"
            end
          end
        end
        TEXT_FORMS[[base,type]] ||= []
        TEXT_FORMS[[base,type]] << [form.downcase,tags[1..-1].join(":")]
      end
    end
  end
  puts "Reading of file finished. Flexemes count: #{TEXT_FORMS.size}"
else
  puts "Reading from CLP"
  require 'rlp'
  require File.join(".",File.dirname(__FILE__),"clp_to_rlp")
  Rlp::Client.instance.encoding = 'utf-8'
  lexemes = []
  if MISSING_FORMS
    MISSING_FORMS.each do |form,types|
      lexemes += Rlp::Lexeme.find(form).select{|l| l.base_form == form}
    end
  else
    lexemes = Rlp::Lexeme.each
  end
  puts "Missing: #{MISSING_FORMS.inject(0){|s,e| s + e[1].size}}, Lexemes: #{lexemes.size}"
  lexemes.each.with_index do |lexeme,index|
    # ignore verbs with reflexive segment
    next if lexeme.base_form =~ /\s/
    lexeme.forms.each do |form|
      positions = lexeme.send(:tag_ids,form)
      next if positions.empty?
      positions.each do |position|
        next if Clp2Rlp.invalid?(position,lexeme.inflection_label)
        tags,subtype = Clp2Rlp.tags_and_type_for(position,lexeme.inflection_label)
        type,gender = subtype.split(":")
        tags = "#{tags}:#{gender}" if gender
        if MISSING_FORMS.nil? || MISSING_FORMS[lexeme.base_form].include?(type)
          TEXT_FORMS[[lexeme.base_form,subtype]] ||= []
          TEXT_FORMS[[lexeme.base_form,subtype]] << [form.downcase,tags]
        end
      end
    end
    break if LIMIT && index > LIMIT
    puts index if index % 10000 == 0
  end
  puts "Reading of CLP. Flexemes count: #{TEXT_FORMS.size}"
end

RLP_FORMS = {}
total = 0
matched = 0
present = 0
old_time = Time.now
ambiguity = Hash.new(0)
MISSING_TYPES = Hash.new{|h,e| h[e] = []}
File.open("work/errors.txt","w") do |errors|
  File.open("work/missing_paradigms.txt","w") do |missing|
    File.open("work/ambig_paradigms.txt","w") do |ambig|
      TEXT_FORMS.each do |base_subtype,forms_tags|
        begin
          base,subtype = base_subtype
          type,gender = subtype.split(":")
          type = Rlp::Grammar::FlexemeType.for_tag(type.to_sym)
          forms = {}
          tags = []
          forms_tags.each{|f,t| forms[f] ||= []; forms[f] << t}
          forms.each{|f,ts| tags << ts}

          tags.each.with_index do |tag_set,tags_index|
            new_tag_set = []
            tag_set.each do |values_str|
              values = values_str.split(":").map{|v| v.to_sym}.
                select do |value|
                begin
                  (type.inflective_categories.to_a + type.defective_categories.to_a).
                    include?(Rlp::Grammar::Value.for_tag(value).category)
                rescue Rlp::Grammar::RlpException => ex
                  puts ex
                  false
                end
              end.sort
              #TODO #1 canonical order
              new_tag_set << values
            end
            tags[tags_index] = new_tag_set
          end
          forms = forms.keys
          total += 1
          puts total if total % 100 == 0
          #good_type = type.paradigms.size == 0 ? substitute_type(type) : type
          paradigms_forms = Rlp::Grammar::Paradigm.multiguess(forms,type,tags,gender)
          total += paradigms_forms.size - 1 if paradigms_forms.size > 1

          klass = type.to_class
          other_flexemes = klass.find_all_by_lemma(base)
          paradigms_forms.each do |paradigms,forms,tags|
            if paradigms.empty?
              missing.puts "#{base} #{type.to_sym} #{forms} #{tags}"
              next
            end
            matched += 1
            if paradigms.size > 1
              ambig.puts "#{base} #{type.to_sym} #{forms} #{tags} #{paradigms.map{|p| p.code}}"
              next
            end
            paradigm = paradigms.first
#            if type != good_type
#              MISSING_TYPES[type.tag] << paradigm
#            end

            if other_flexemes.any?{|f| f.paradigm == paradigm}
              present += 1
              next
            end

            rlp_flexeme = klass.new(:lemma => base)
            rlp_flexeme.paradigm = paradigm
            forms.each do |form|
              rlp_form = RLP_FORMS[form]
              if rlp_form.nil?
                rlp_form = Rlp::Grammar::WordForm.find_by_value(form)
                if rlp_form.nil?
                  rlp_form = Rlp::Grammar::WordForm.new(:value => form)
                  rlp_form.store
                end
                RLP_FORMS[form] = rlp_form
              end
              rlp_form.flexemes << rlp_flexeme
            end
            rlp_flexeme.word_forms = paradigm.sort(forms).map{|f| RLP_FORMS[f]}
            rlp_flexeme.store
          end
          if total % 1000 == 0
            RLP_FORMS.each do |str,form|
              form.store
            end
            RLP_FORMS.clear
            now = Time.now
            puts "#{total} #{now - old_time}"
            old_time = now
          end
          if total % 10000 == 0
            Rlp::Grammar::Client.instance.close_database
            Rlp::Grammar::Client.instance.open_database("tmp/rlp-grammar",:readonly => false)
            GC.start
          end
        rescue Exception => ex
          puts "Exception for #{base_subtype} #{ex}"
          puts ex.backtrace[0..15].join("\n")
          errors.puts("#{base_subtype} #{ex}")
        end
      end
      RLP_FORMS.each do |str,form|
        form.store
      end
      puts "matched/present/total #{matched}/#{present}/#{total}"
      #print "forms ambiguity: "
      #puts ambiguity.sort_by{|k,v| -v}.map{|k,v| "#{k} : #{v}"}.join(", ")
    end
  end
end

#File.open("work/missing_types.txt","w") do |types_file|
#  MISSING_TYPES.each do |type,paradigms|
#    types_file.puts "#{type.tag} #{paradigms.map{|p| p.code}.uniq}"
#  end
#end

Rlp::Grammar::Client.instance.close_database
