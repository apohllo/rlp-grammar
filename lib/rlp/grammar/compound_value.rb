# encoding: utf-8
require 'rlp/grammar/value'

module Rlp
  module Grammar
    # Class representing compound values, such as 'm1.m2.m3'.
    class CompoundValue < Value
      has_many :values

      def initialize(*args)
        super(*args)
        if args[0].is_a?(Hash)
          if args[0][:values]
            self.tag = args[0][:values].map{|v| v.to_sym}.join(".").to_sym
            self.name = args[0][:values].map{|v| v.name}.join(", ")
            self.category = args[0][:values].first.category
          end
        end
      end
    end
  end
end
