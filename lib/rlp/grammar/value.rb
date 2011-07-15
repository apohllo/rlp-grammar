# encoding 'utf-8'

module Rlp
  module Grammar
    # This class represents various grammar
    # (flexemic and syntactic) categories' values.
    class Value < Model
      field :tag, :object, :index => true
      field :name, :string, :index => true
      has_one :category

      # A string representation of the value.
      def to_s
        "Grammatical value from '#{self.category.name}': #{self.tag} - '#{self.name}'"
      end

      # A symbol representation of the category.
      def to_sym
        self.tag
      end

      # Returns grammar category value for given +tag+.
      def self.for_tag(tag)
        if tag.to_s =~ /\./
          # TODO This will be removed when Rod fully supports inheritence.
          value = self.find_by_tag(tag)
          return value if value
          values = tag.to_s.split(".").map{|v| self.for_tag(v.to_sym)}
          value = CompoundValue.new(:values => values)
        else
          value = self.find_by_tag(tag)
          raise RlpException.new("There is no grammar category value for tag '#{tag}'.") if value.nil?
        end
        value
      end

      # Returns grammar category value with given +name+.
      def self.for_name(name)
        value = self.find_by_name(name)
        raise RlpException.new("There is no grammar category value for name '#{name}'.") if value.nil?
        value
      end
    end
  end
end
