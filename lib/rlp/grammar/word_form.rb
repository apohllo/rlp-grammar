require 'rlp/grammar/model'

module Rlp
  module Grammar
    class WordForm < Model
      # The value of the word form, i.e. its string representation.
      field :value, :string, :index => :hash

      # A list of flexems given word form belongs to.
      has_many :flexemes, :polymorphic => true

      ###################################################
      # Experimental
      ###################################################

      # The probability of finding this word form in some corpus.
      field :corpus_probability, :float

      # The position of the word form in a sequence sorted according
      # to the word form's corpus probability normalized to [0..1].
      field :corpus_position, :float

      # The probability of finding this word form in some semantic dictionary.
      field :semantic_probability, :float

      # The position of the word form in a sequence sorted according
      # to the word form's semantic probability normalized to [0..1].
      field :semantic_position, :float

      # The word forms have to be in lower case
      validates_format_of :value, :with => /\A[^[:upper:]]*\Z/

      validates_numericality_of :corpus_probability,
        :greater_than_or_equal_to => 0.0,
        :less_than_or_equal_to => 1.0,
        :allow_nil => true
      validates_numericality_of :corpus_position,
        :greater_than_or_equal_to => 0.0,
        :less_than_or_equal_to => 1.0,
        :allow_nil => true
      validates_numericality_of :semantic_probability,
        :greater_than_or_equal_to => 0.0,
        :less_than_or_equal_to => 1.0,
        :allow_nil => true
      validates_numericality_of :semantic_position,
        :greater_than_or_equal_to => 0.0,
        :less_than_or_equal_to => 1.0,
        :allow_nil => true
    end
  end
end
