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
        mod.field :space_after, :string
        mod.field :position, :integer
        mod.has_one :form, :class_name => "Rlp::Grammar::WordForm", :index => :hash
        mod.validates :position, :numericality => {:greater_than_or_equal_to => 0}
        mod.validates :form, :presence => true
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
        self.form.flexemes
      end

      # Returns forms linked with the word form (including itself) of this segment.
      def linked_forms
        flexemes = self.flexemes
        if flexemes.count > 0
          flexemes.map{|f| f.word_forms.to_a}
        else
          [self.form]
        end.flatten.uniq
      end

      # Default string representation of the text segment.
      def to_s
        self.word_form + self.space
      end

      # Returns the space after the text segment with breaklines changed into spaces.
      def space
        @space ||= self.space_after.gsub(/\s*(\n|\r)+\s*/," ")
      end
    end
  end
end
