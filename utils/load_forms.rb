#!/bin/env ruby

$:.unshift "lib"
require 'rlp'
require 'rod'

# Rod::Database.development_mode = true


def get_flexeme(lemma,tags,flexemes)
  tags = tags.split(":")
  unless flexemes["#{lemma}+#{tags}"]
    flexeme = Rlp::Flexeme.class_for(tags[0]).new
    flexemes["#{lemma}+#{tags}"] = flexeme
    flexeme.lemma = lemma
  end
  flexemes["#{lemma}+#{tags}"]
end

FLEXEMES = {}
FileUtils.mkdir("tmp") if !File.exist?("tmp")
Rlp::Client.instance.create_database("tmp/seed.dat")

File.open(ARGV[0]) do |file|
  file.each do |line|
    line.chomp!
    form, lemma, tags = line.split(/\s+/)
    rlp_form = Rlp::WordForm.new
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
Rlp::Client.instance.close_database
