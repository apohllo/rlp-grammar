# encoding: utf-8
require 'rlp/static_model'

module Rlp
  # This class represtens various grammar (flexemic and syntactic) categories.
  class GrammarCategory < StaticModel
    field :tag, :object, :index => true
    field :name, :string, :index => true
    has_many :values

    # String representation of the grammar category.
    def to_s
      "Grammar category: #{self.tag} - '#{self.name}'"
    end

    # Returns the category instance for given category +tag+.
    def self.for_tag(tag)
      category = self.find_by_tag(tag)
      raise RlpException.new("There is no grammar category for tag '#{tag}'.") if category.nil?
      category
    end

    # Returns the category instance for given category +name+.
    def self.for_name(name)
      category = self.find_by_name(name)
      raise RlpException.new("There is no grammar category for name '#{name}'.") if category.nil?
      category
    end
  end
end
