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
    end
  end
end
