# encoding: utf-8

module Rlp
  module Grammar
    class Flexeme
      class Noun < Flexeme
        def requirements
          @requirements ||= [{Category.for_tag(:case) => Value.for_tag(:gen)}]
        end

        def values_for(form)
          self.positions_for(form).each{|vs| vs << self.paradigm.gender}
        end
      end
    end
  end
end
