# encoding: utf-8

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
  when /czas$/
    :tense
  when /kropki$/
    :punct
  else
    raise "Unknown category '#{name}'"
  end
end

def get_value(name)
  case name
  when /rządzącą/
    :rec
  when /uzgadniającą/
    :congr
  when /pojedynczą/
    :sg
  when /mnogą/
    :pl
  when /teraźniejszy/
    :present
  when /przeszły/
    :past
  when /przyszły/
    :future
  when /niedokonany/
    :imperf
  when /dokonany/
    :perf
  when /oznajmuj/
    :indic
  when /przypuszcz/
    :cond
  when /rozkazuj/
    :imper
  else
    raise "Unknown value '#{name}'"
  end
end
