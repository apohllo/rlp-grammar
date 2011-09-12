require 'rlp/grammar/model'

module Rlp
  module Grammar
    class WordForm < Model
      field :value, :string, :index => :hash
      has_many :flexemes, :polymorphic => true
    end
  end
end
