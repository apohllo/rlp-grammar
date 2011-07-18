# encoding: utf-8
require 'rlp/grammar/word_form'

module Rlp
  module Grammar
    # This module contains useful predicates for text segments.
    # These are convenience methods for checking letter case,
    # form types, etc. which are not defined as grammar category
    # values.
    module SegmentPredicates
      # Returns true if the segment has nominal case and has
      # default number (mostly :sg).
      def nominal?
        # TODO #14 should use disambiguated position if present.
        fixed_form = self.fixed_form
        self.flexemes.any? do |flexeme|
          positions = flexeme.positions_for(fixed_form)
          # TODO plurale tantum!
          positions.any?{|p| p && p.include?(Value.for_tag(:nom)) &&
            p.include?(Value.for_tag(:sg))}
        end
      end

      # Returns true if the segment is a quote.
      def quote?
        self.form.value =~ /["'\p{Pi}\p{Pf}]/
      end

      # Returns ture if the first letter is capital.
      def first_capital?
        self.letter_case[0] == "M"
      end
    end
  end
end
