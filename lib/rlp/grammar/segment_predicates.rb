# encoding: utf-8
require 'rlp/grammar/word_form'
require 'set'

module Rlp
  module Grammar
    # This module contains useful predicates for text segments.
    # These are convenience methods for checking letter case,
    # form types, etc. which are not defined as grammar category
    # values.
    module SegmentPredicates

      # TODO move to FlexemeType
      CLOSED_TYPES = Set.new([:ppron12, :ppron3, :siebie,:pronbgen,:prondef,:imppron,
        :ppron,:aglt,:acond,:prep,:conj,:qub,:interp])
      VERBAL_TYPES = Set.new([:praet,:fin,:bedzie,:aglt,:acond,:impt,:imps,:inf,:pcon,:pant,:pant,
        :pact,:ppas,:imptdef,:anl,:impspres, :impspast])
      NOUN_TYPES = Set.new([:subst,:depr,:sdef,:xxs,:ppron12,:ppron3,:pronbgen,
        :prondef,:imppron,:ppron,:ger,:brev])
      STRICT_NOUN_TYPES = Set.new([:subst,:depr,:sdef,:xxs,:ger,:brev])
      ADJECTIVE_TYPES = Set.new([:adj,:adja,:adjp,:adjdef,:pact])

      COMMA = ","
      LINKING = /\A(i|oraz)\Z/
      QUOTE = /["'\p{Pi}\p{Pf}]/
      PUNCTUATION = /\p{P}/
      DASH = /\p{Pd}/
      NUMBER = /\A\d+([.,]\d+)?\Z/

      # Returns true if the segment has nominal case and has
      # default number (mostly :sg).
      def nominal?
        if self.respond_to?(:flexeme) && self.flexeme
          flexemes = [self.flexeme]
        else
          flexemes = self.flexemes
        end
        flexemes.any? do |flexeme|
          values = flexeme.values_for(self.form)
          # TODO plurale tantum!
          values.any?{|v| v && v.include?(Value.for_tag(:nom)) &&
            (v.include?(Value.for_tag(:sg)) ||
             (v.any?{|vv| vv === Value.for_tag(:"p1.p2.p3")} &&
              v.include?(Value.for_tag(:pl))))}
        end
      end

      # Returns true if the segment is in verbal position, i.e.
      # is a verb which is not gerund.
      def verbal?
        self.form.flexemes.any?{|f| VERBAL_TYPES.include?(f.type.tag)}
      end

      # Returns true if the segment is a preposition.
      def preposition?
        self.form.flexemes.any?{|f| f.type.tag == :prep}
      end

      # Returns true if the segment is a number (1).
      def number?
        self.form.value =~ NUMBER
      end

      # Returns true if the segment is noun-like.
      def noun?
        self.form.flexemes.any?{|f| NOUN_TYPES.include?(f.type.tag)}
      end

      # Returns true if the segment is an adjective.
      def adjective?
        self.form.flexemes.any?{|f| ADJECTIVE_TYPES.include?(f.type.tag)}
      end

      # Returns true if the segment is an adverb.
      def adverb?
        self.form.flexemes.any?{|f| f.type.tag == :adv}
      end

      # Returns true if the flexeme is a punctuation.
      def punctuation?
        self.form.value =~ PUNCTUATION
      end

      # Retruns true if the segment is a comma (,).
      def comma?
        self.form.value == COMMA
      end

      # Returns true if the segment is any kind of dash (-).
      def dash?
        self.form.value =~ DASH
      end

      # Returns true if the segment is a conjunction?
      def conjunction?
        self.form.flexemes.any?{|f| f.type.tag == :conj}
      end

      # Returns true if the segment is a linking conjunction (i,oraz).
      def linking_conjunction?
        self.form.value =~ LINKING
      end

      # Returns true if the segment is a quote.
      def quote?
        self.form.value =~ QUOTE
      end

      # Returns ture if the first letter is capital.
      def first_capital?
        self.letter_case[0] == "M"
      end

      # Returns true if given segment is a regular word, i.e. consists only
      # of letters.
      def word?
        # TODO #12 - chagne to :lower: only
        self.form.value =~ /\A[[:lower:][:upper:]]+\Z/
      end

      # Returns true if the segment is a word which belongs to open
      # grammatical category.
      def open_class_word?
        return false if !word?
        if form.flexemes.count == 0
          false
        else
          form.flexemes.any?{|f| !CLOSED_TYPES.include?(f.type.tag)}
        end
      end
    end
  end
end
