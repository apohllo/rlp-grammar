# encoding: utf-8

module Rlp
  module Grammar
    class Flexeme
      class Preposition < Flexeme
        def requirements(type=:government)
          raise RlpException.new("Preposition has only government requirements") if type != :government
          return @governance if defined?(@governance)
          @governance =
            case self.lemma
            when /\A(bez|dla|dokoła|gwoli|koło|naokoło|od|oprócz|do|podczas|pomimo|prócz|skroś|skutkiem|spod|spode|spomiędzy|sponad|spośród|spoza|sorzed|u|według|wewnątrz|wkoło|wokoło|wokół|wskutek|wśród|wzdłuż|względem|znad|zza|naokół)\Z/
              [{:case => :gen}]
            when /\A(między|nad|pod|pomiędzy|ponad|popod|poza|przed)\Z/
              [{:case => :acc},{:case => :inst}]
            when /\A(dzięki|ku|przeciw|przeciwko|wbrew)\Z/
              [{:case => :dat}]
            when /\A(w|przy|we)\Z/
              [{:case => :loc}]
            when /\A(z|zamiast)\Z/
              [{:case => :gen},{:case => :inst}]
            when /\A(na|o|po)\Z/
              [{:case => :acc},{:case => :loc}]
            when /\A(poprzez|przez|przeze|lada)\Z/
              [{:case => :acc}]
            when /\A(naprzeciw)\Z/
              [{:case => :dat},{:case => :gen}]
            when /\A(za)\Z/
              [{:case => :gen},{:case => :inst},{:case => :acc}]
            when /\A(kontra)\Z/
              # requires 2 complements
              [{:case => :nom}]
            when /\A(mimo)\Z/
              [{:case => :acc},{:case => :gen}]
            when /\A(via)\Z/
              [{:case => :acc},{:case => :nom}]
            when /\A(naprzeciwko)\Z/
              [{:case => :nom},{:case => :gen}]
            else
              raise RlpException.new("Unknown preposition: #{self.lemma}")
            end
          @governance
        end
      end
    end
  end
end
