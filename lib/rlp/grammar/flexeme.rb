require 'rlp/grammar/model'
require 'rlp/grammar/exception'

module Rlp
  module Grammar
    class Flexeme < Model
      # The +lemma+ of the flexeme, i.e. its base form.
      field :lemma, :string, :index => true

      # The paradigm of the flexeme, i.e. the way the flexeme
      # inflects itself.
      has_one :paradigm, :class_name => "Rlp::Grammar::Paradigm"

      # The +word_forms+ of the flexeme, sorted according to the
      # order of +paradigm+'s suffixes.
      has_many :word_forms, :class_name => "Rlp::Grammar::WordForm"

      # For given +form+ find all lexemes posessing it.
      def self.find(form)
        rlp_form = WordForm.find_by_value(form)
        rlp_form && rlp_form.flexemes || []
      end

      # Returns the type of the flexeme.
      def type
        FlexemeType.for_class_name(self.class.to_s)
      end

      # Does the flexeme have a defined value for given
      # flexemic +category+?
      def has?(category)
        self.respond_to?(category)
      end

      # Dose the flexeme inflect for given flexemic +category+?
      def inflects_for?(category)
        !self.positions(category).nil?
      end

      # Returns all the inflection positions (sets of tags which might
      # have distinct forms) of given flexeme. If +category+ is given,
      # only the values of the category for which the flexeme has forms
      # are returned.
      def positions(category=nil)
        self.type.positions(category)
      end

      # String representation of the lexeme.
      def to_s
        "Flexeme[#{self.type.tag}]: #{self.lemma}"
      end

      # Flexeme with full inflectional paradigm.
      def pretty_to_s
        "#{self.lemma}[#{self.rod_id}] : #{self.type.name} #{self.paradigm.code}\n" +
          self.paradigm.pretty_to_s(self.word_forms.map{|f| f && f.value})
      end

      # Returns all inflection positions occupied by given word +form+.
      # E.g. [[:nom,:sg]] for form "kot" for flexeme "kot subst:m2".
      # Note: the values returned are instances of Value, not Symbol.
      # Raises InvalidArgument if the form does not belong to the flexeme.
      def positions_for(form)
        # TODO optimize ?
        index = self.word_forms.each.with_index{|wf,i| break i if wf == form}
        raise InvalidArgument.new(self.class,:tags_for,form) unless index.is_a?(Fixnum)
        positions = self.paradigm.mapping[index]
        raise RlpException.new("Missing positions for #{form} in flexeme #{self}") if positions.nil?
        positions[1].map{|ps| ps && ps.map{|v| v && Value.for_tag(v)}}
      end

      # Inflectional requirements for given lexeme if it is a governor in
      # a government binding.
      # E.g. verb "gonić" requires accusative case for its object.
      #
      # This method should return a list, since alternative requirements
      # are possible.  The list should contain requirements in form of a
      # grammar category - value pairs.
      #
      # The list is empty by default, thuse the requirements are never met.
      def requirements
        []
      end
    end
  end
end
