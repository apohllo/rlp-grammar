require 'rlp/model'
require 'rlp/exception'

module Rlp
  class Flexeme < Model
    field :lemma, :string, :index => true
    has_many :word_forms, :class_name => "Rlp::WordForm"

    # For given +form+ find all lexemes posessing it.
    def self.find(form)
      rlp_form = WordForm.find_by_value(form)
      rlp_form && rlp_form.flexemes || []
    end

    # Returns the type of the flexeme.
    def type
      FlexemeType.for_class_name(self.class.to_s)
    end

    # Dose the flexeme have a defined value for given
    # flexemic +category+?
    def has?(category)
      raise AbstractMethod.new(self.class,"has?")
    end

    # Dose the flexeme inflect for given flexemic +category+?
    def inflects_for?(category)
      raise AbstractMethod.new(self.class,"inflects_for?")
    end

    # Returns all the inflections (word form + tags) of given flexeme.
    def inflections
      raise AbstractMethod.new(self.class,"inflections")
    end

    # String representation of the lexeme.
    def to_s
      "Flexeme[#{self.type.tag}]: #{self.lemma}"
    end
  end
end
