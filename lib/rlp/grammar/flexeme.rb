require 'rlp/grammar/model'
require 'rlp/grammar/exception'

module Rlp
  module Grammar
    class Flexeme < Model
      # The +lemma+ of the flexeme, i.e. its base form.
      field :lemma, :string, :index => true

      # The paradigm of the flexeme, i.e. the way the flexeme
      # inflects itself.
      has_one :paradigm, :class_name => "Rlp::Grammar::Paradigm"

      # The +word_forms+ of the flexeme, sorted according to the
      # order of +paradigm+'s suffixes.
      has_many :word_forms, :class_name => "Rlp::Grammar::WordForm"

      # For given +form+ find all lexemes posessing it.
      def self.find(form)
        rlp_form = WordForm.find_by_value(form)
        rlp_form && rlp_form.flexemes || []
      end

      # Returns the type of the flexeme.
      def type
        FlexemeType.for_class_name(self.class.to_s)
      end

      # Does the flexeme have a defined value for given
      # flexemic +category+?
      def has?(category)
        self.respond_to?(category)
      end

      # Dose the flexeme inflect for given flexemic +category+?
      def inflects_for?(category)
        !self.positions(category).nil?
      end

      # Returns all the inflection positions (sets of tags which might
      # have distinct forms) of given flexeme. If +category+ is given,
      # only the values of the category for which the flexeme has forms
      # are returned.
      def positions(category=nil)
        self.type.positions(category)
      end

      # String representation of the lexeme.
      def to_s
        "Flexeme[#{self.type.tag}]: #{self.lemma}"
      end
    end
  end
end
