# encoding: utf-8

module Rlp
  module Grammar
    class Flexeme
      class Noun < Flexeme
        field :lcase, :string
        has_one :gender, :class_name => "Rlp::Grammar::Value"

        def values_for(form)
          self.positions_for(form).each{|vs| vs << self.paradigm.gender}
        end
      end
    end
  end
end
