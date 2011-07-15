# encoding: utf-8
require 'rlp/grammar/model'

module Rlp
  module Grammar
    # This class represents the inflectional paradigm of flexemes.
    # It is connected with specific flexeme type and is used to:
    # * differentiate flexemes of given type inflecting in a different way
    # * obtain the mapping between unique flexeme word forms and their
    #   inflectional positions
    #
    # The paradigm with the flexeme lemma allows for obtaining all
    # inflectional positions of given flexemes and as such allows
    # for exchanging data between natural language processing
    # information systems.
    class Paradigm < Model
      # The code of the paradigm. Should be stable as much as
      # possible. It is comupted as first 6 hex-digits of the
      # SHA2 hash of common forms suffixes (in a-targo order)
      # prefixed with the flexeme type tag and gender (if applicable).
      # These elements are joined with colons.
      # E.g. (Digest::SHA2.new << "subst:m1:a:ac:e:owie:ami:owi:ł:em:om:ów").
      #   hexdigest[0...6] => "ebe733"
      field :code, :string, :index => :flat

      # A mapping (as an array) between flexemic positions and form positions, i.e.
      # for given flexemic position the position of a form (i.e. its
      # index in flexeme#word_forms) is returned.
      field :form_position, :object

      # A list of common suffixes of all flexemes belonging to this
      # paradigm (in order of the forms in the flexemes). They
      # are sorted in a-targo order.
      field :suffixes, :object

      # The +flexeme_type+ given paradigm belongs to.
      has_one :flexeme_type

      # The +gender+ of the paradigm. This is not applicable to all paradigms,
      # so the value might be +nil+. But there are paradigms, which have the
      # same suffixes, but have different form p. - flexemic p. mappings.
      # Thats why we have to differentiate them.
      has_one :gender, :class_name => "Rlp::Grammar::Value"

      # Updates the code of the paradigm. See the description of +code+
      # for the algorithm specification.
      def update_code
        elements = [flexeme_type.tag.to_s]
        elements << gender.tag.to_s if gender
        elements += suffixes
        self.code = (Digest::SHA2.new << elements.join(":")).hexdigest[0...6]
      end

      # A mapping between form positions and flexemic positions, i.e.
      # for given form position a list of flexemic position indices
      # of given flexeme type is returned.
      def flexemic_positions
        return @flexemic_positions if defined?(@flexemic_positions)
        @flexemic_positions = {}
        self.form_position.each.with_index do |position,index|
          @flexemic_positions[position] ||= []
          @flexemic_positions[position] << index
        end
        @flexemic_positions
      end


      # Returns the mapping between suffixes and flexemic positions.
      # Options:
      # * +:type+ :
      # ** +:short+     - suffix -> positions (default)
      # ** +:long+      - position -> suffix
      # ** +:canonical+ - like +:short+ but with tags sorted
      def mapping(options={:type => :short})
        case options[:type]
        when :long
          self.form_position.map.with_index do |findex,pindex|
            tags = self.flexeme_type.inflections[pindex]
            [findex && self.suffixes[findex], tags]
          end
        when :canonical
          # #1 use FlexemeType canonical order
          mapping(:type => :short).map{|s,ts| [s,ts.map{|t| t && t.sort}]}
        else
          self.suffixes.map.with_index do |suffix,index|
            tags = self.flexemic_positions[index].
              map{|idx| self.flexeme_type.inflections[idx]}
            [suffix,tags]
          end
        end
      end

      # Returns a regular expression matching the suffixes of this
      # paradigm. The suffixes are concatenated in reverse order,
      # to ensure that the longest suffix os suffixes sharing their
      # end is matched first.
      def suffix_matcher
        return @suffix_matcher if defined?(@suffix_matcher)
        re = self.suffixes.reverse.map{|e| "(#{e})"}.join("|")
        @suffix_matcher = /(?:#{re})$/
      end

      # Returns the +forms+ sorted in the order of the suffixes.
      # If +tags+ are given, the +forms+ are sorted against the
      # +tags+, not against the paradigm suffixes.
      def sort(forms,tags=nil)
        # #7 this causes tags - forms mismatch
        forms = forms.uniq
        matcher = self.suffix_matcher
        result = []
        if tags
          tags = tags.map{|ts| ts.map{|t| t.sort}}
        end
        forms.each.with_index do |form,form_index|
          if tags
            index = self.tags_index(tags[form_index])
            result[index] = form if index
          else
            matched = matcher.match(form)
            next if matched.nil?
            reverse_position = matched.captures.each.
              with_index{|m,i| break i if m}
            result[forms.size-reverse_position-1] = form
          end
        end
        result
      end

      # Tries to guess the inflection paradigm of the forms. If +type_tag+
      # is given, the results is less ambigious
      def self.guess(forms,type_tag=nil,options={})
        forms = forms.uniq
        if type_tag
          result =
          FlexemeType.for_tag(type_tag).paradigms.map do |paradigm|
            #matchers = paradigm.suffixes.reverse.map{|s| /#{s}$/}
            matched = {}
            matched_count = 0
            matchers_size = nil
            suffix_matcher = paradigm.suffix_matcher
            forms.each do |form|
              #match = matchers.find{|m| m.match(form)}
              match_data = suffix_matcher.match(form)
              if match_data
                match = match_data.captures.find{|c| c}
                matchers_size ||= match_data.captures.size
                matched_count += match.size
                matched[match] = true
              end
            end
            [paradigm,matched.size,matchers_size,matched_count]
          end.select do|paradigm,matched_s,matchers_s,matched_c|
            #matched_s >= forms.size
            matched_s == forms.size && matched_s == matchers_s
          end.sort_by do |paradigm,matched_s,matchers_s,matched_c|
            #- matched_c * matched_s.to_f / matchers_s
            - matched_c * matched_s
          end
          result = result[0..5]
          unless options[:with_counts]
            result.map!{|p,i1,i2,i3| p}
          end
          result
        else
          raise "TODO implement"
        end
      end
    end
  end
end
