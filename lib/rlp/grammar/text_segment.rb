# encoding: utf-8
require 'rlp/grammar/word_form'

module Rlp
  module Grammar
    # The module defines +letter_case+ field and has one +form+.
    # It centralizes management of segment's letter case and creation
    # of word forms for segments.
    module TextSegment
      def self.included(mod)
        mod.field :letter_case, :string
        mod.has_one :form, :class_name => "Rlp::Grammar::WordForm", :index => :segmented
      end

      # Assigns word form for this text segment as +string+.
      def word_form=(string)
        self.letter_case = string.each_char.map do |char|
          case char
          when /\p{Lower}/
            "m"
          when /\p{Upper}/
            "M"
          else
            "x"
          end
        end.join("").sub(/(.)(\1)+$/,"\\1+")
        string.downcase!
        rlp_form = Rlp::Grammar::WordForm.find_by_value(string)
        if rlp_form.nil?
          rlp_form = Rlp::Grammar::WordForm.new(:value => string)
          rlp_form.store
        end
        self.form = rlp_form
      end

      # Reads the word form of this segment as string with proper case.
      def word_form
        self.form.value.each_char.map.with_index do |char,index|
          case self.letter_case[index]
          when "M"
            char.upcase
          when "+",nil
            if self.letter_case[-2] == "M"
              char.upcase
            else
              char
            end
          else
            char
          end
        end.join("")
      end

      # Returns flexemes linked with the segment. If segment
      # is disambiguated, only one flexeme is returned.
      # TODO # 11 add flexeme field.
      def flexemes
        # TODO #12 fix case in semantics export script!!!
        if segment.form.value =~ /^[[:upper:]]/
          form = Rlp::Grammar::WordForm.find_by_value(segment.word_form.downcase)
          form && form.flexemes || []
        else
          segment.form.flexemes
        end
      end

      # Returns forms linked with the word form (including itself) of this segment.
      def linked_forms
        flexemes = self.flexemes
        if flexemes.count > 0
          flexemes.map{|f| f.word_forms.to_a}
        else
          [segment.form]
        end.flatten
      end
    end
  end
end
