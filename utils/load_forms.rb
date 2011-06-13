#!/bin/env ruby

$:.unshift "lib"
require 'rlp/grammar'
require 'rod'

# Rod::Database.development_mode = true


def get_flexeme(lemma,tags,flexemes)
  tags = tags.split(":")
  unless flexemes["#{lemma}+#{tags}"]
    flexeme = Rlp::Grammar::FlexemeType.for_tag(tags[0].to_sym).to_class.new
    flexemes["#{lemma}+#{tags}"] = flexeme
    begin
      flexeme.lemma = lemma
    rescue
      puts Rlp::Grammar::FlexemeType.for_tag(tags[0].to_sym).to_class
    end
  end
  flexemes["#{lemma}+#{tags}"]
end

FLEXEMES = {}
FileUtils.mkdir("tmp") if !File.exist?("tmp")
Rlp::Grammar::Client.instance.open_database("tmp/rlp-grammar",false)

File.open(ARGV[0]) do |file|
  file.each do |line|
    line.chomp!
    form, lemma, tags = line.split(/\s+/)
    rlp_form = Rlp::Grammar::WordForm.new
    rlp_form.value = form
    rlp_flexeme = get_flexeme(lemma,tags,FLEXEMES)
    rlp_flexeme.lemma = lemma
    rlp_flexeme.word_forms << rlp_form
    rlp_form.flexemes << rlp_flexeme
    rlp_form.store
  end
end
FLEXEMES.values.each do |rlp_flexeme|
  rlp_flexeme.store
end
Rlp::Grammar::Client.instance.close_database
