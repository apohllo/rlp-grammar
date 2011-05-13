require 'rlp/model'

module Rlp
  class WordForm < Model
    field :value, :string, :index => true
    has_many :flexemes, :polymorphic => true
  end
end
