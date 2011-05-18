# encoding: utf-8

module Rlp
  class Flexeme
    class Noun < Flexeme
      field :lcase, :string
      has_one :gender, :class_name => "Rlp::Value"

    end
  end
end
