# encoding: utf-8
require 'rlp/grammar/model'

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
      # The +tag+ i.e. short name of the flexeme type in form of a symbol.
      field :tag, :object, :index => :hash

      # The descriptive +name+ of the flexeme type.
      field :name, :string, :index => :hash

      # The name of the class implementing given flexeme type.
      field :class_name, :string, :index => :hash

      # The inflections array, i.e. an array containing all the inflectional
      # positions (sets of grammatical categories' values) defined for the
      # flexeme type.
      field :inflections, :object

      # A map of grammatical categories' values which are fixed for this
      # flexeme type.
      field :fixed_values, :object

      # The conditional probability of each position.
      # The value is a hash of pairs:
      # * inflectional positions' tags -> probability
      field :positions_probability, :object


      # A list of grammatical categoreis, which this flexeme type inflects for.
      has_many :inflective_categories, :class_name => "Rlp::Grammar::Category"

      # A list of grammatical categories, which this flexeme type doesn't
      # inflect for, but all its instances have some value of the category
      # definded.
      has_many :rigid_categories, :class_name => "Rlp::Grammar::Category"

      # Like +inflective_categories+, but some combinations of grammatical
      # values of these categories and other categories are forbidden.
      has_many :defective_categories, :class_name => "Rlp::Grammar::Category"

      # The +paradigms+ of the flexeme type, i.e. the specific types of inflection.
      has_many :paradigms

      # Returns a class implementing this flexeme type.
      def to_class
        return @to_class unless @to_class.nil?
        begin
          @to_class = self.class_name.split("::").inject(Object){|m,n| m.const_get(n,false)}
        rescue
          raise RlpException.new("Flexemic class '#{self.class_name}' not implemented yet.")
        end
      end

      # Returns symbol representation of the flexeme type.
      def to_sym
        self.tag
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
          return @positions if defined?(@positions)
          @positions = inflections.map{|i| i.map{|v| Value.for_tag(v)}}
        else
          values = []
          inflections.each do |inflection|
            values << inflection.find{|v| Value.for_tag(v).category == category}
          end
          values.uniq.compact.map{|v| Value.for_tag(v)}
        end
      end

      # The hash returned indicates how many binds given
      # flexeme type might have for the other flexeme type. If there is no
      # indication for given type, it means that there is no restriction
      # on the number of binds of that type. The special type +:total+
      # indicates the maximum total number of binds.
      #
      # E.g. preposition should have only one binde with one noun and
      # conjunction usually has two noun or adjective binds.
      #
      # TODO should be in lexeme type.
      # TODO #15 should be externalized.
      # TODO work out the direction of binds
      def bind_counts
        # TODO make complete
        case self.tag
        when :conj
          {:total => 2}
        else
          {:total => 1}
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
