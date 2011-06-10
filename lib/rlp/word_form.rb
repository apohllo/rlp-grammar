require 'rlp/model'

module Rlp
  class WordForm < Model
    field :value, :string, :index => :segmented
    has_many :flexemes, :polymorphic => true
  end
end
