# encoding: utf-8

module Rlp
  module Grammar
    # This class represents the types of flexemes. It corresponds
    # to the classes in Rlp::Grammar::Flexeme module, but it provides a
    # separation of concerns. This class holds the information
    # about flexem types (their tags, names, etc.) while the
    # actual classes in Rlp::Grammar::Flexeme only store information about
    # the instances of flexemes. As en effect no data should be stored
    # in large hashes (such as flexeme type name - flexeme type tag),
    # but should be provided via object oriented API.
    class FlexemeType < Model
      field :tag, :object, :index => true
      field :name, :string, :index => true
      field :class_name, :string, :index => true
      field :inflections, :object

      # Returns a class implementing this flexeme type.
      def to_class
        begin
          self.class_name.split("::").inject(Object){|m,n| m.const_get(n)}
        rescue
          raise RlpException.new("Flexemic class '#{self.class_name}' not implemented yet.")
        end
      end

      # String representation of the flexeme type.
      def to_s
        "Flexeme type: #{self.tag} - '#{self.name}'"
      end

      # Returns all the inflection positions (sets of tags which might
      # have distinct forms) of given flexeme type. If +category+ is given,
      # only the values of the category for which the flexemes of this flexeme type
      # have forms are returned.
      def positions(category=nil)
        if category == nil
          values_map = inflections.keys.map{|c| self.positions(c) }
          values_map.inject([[]]) do |sum,values|
            result = []
            sum.each do |pvalues|
              values.each do |value|
                result << pvalues + [value]
              end
            end
            result
          end
        else
          inflections[category.to_sym].map{|v| Value.for_tag(v)}
        end
      end

      # Returns the flexeme type for given flexeme type +tag+.
      def self.for_tag(tag)
        type = self.find_by_tag(tag)
        raise RlpException.new("There is no flexeme type for tag '#{tag}'.") if type.nil?
        type
      end

      # Returns the flexeme type for given flexeme type +name+.
      def self.for_name(name)
        type = self.find_by_name(name)
        raise RlpException.new("There is no flexeme type for name '#{name}'.") if type.nil?
        type
      end

      # Returns the flexeme type for flexeme with give class +name+.
      def self.for_class_name(name)
        type = self.find_by_class_name(name)
        raise RlpException.new("There is no flexeme type for class name '#{name}'.") if type.nil?
        type
      end
    end
  end
end
