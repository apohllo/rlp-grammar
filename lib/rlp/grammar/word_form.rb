require 'rlp/grammar/model'

module Rlp
  module Grammar
    class WordForm < Model
      field :value, :string, :index => :hash
      has_many :flexemes, :polymorphic => true

      # TODO #18 validate format of value to /\A[^[:upper]]*\Z/
    end
  end
end
