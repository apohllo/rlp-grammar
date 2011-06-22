# encoding: utf-8

module Rlp
  module Grammar
    class Flexeme
      class Noun < Flexeme
        field :lcase, :string
        has_one :gender, :class_name => "Rlp::Grammar::Value"
      end
    end
  end
end
