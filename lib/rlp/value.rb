# encoding 'utf-8'
require 'rlp/static_model'

module Rlp
  # This class represents various grammar
  # (flexemic and syntactic) categories' values.
  class Value < StaticModel
    field :tag, :object, :index => true
    field :name, :string, :index => true
    has_one :category, :class_name => "Rlp::GrammarCategory"

    # Returns grammar category value for given +tag+.
    def self.for_tag(tag)
      value = self.find_by_tag(tag)
      raise RlpException.new("There is no grammar category value for tag '#{tag}'.") if value.nil?
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
