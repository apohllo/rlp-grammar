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
      field :code, :string, :index => :hash

      # A mapping (as an array) between flexemic positions and form positions, i.e.
      # for given flexemic position at index +i+ of the +form_position+ array
      # the position of a form (i.e. its index in flexeme#word_forms) is returned.
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
          # TODO #1 use FlexemeType canonical order
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
            index = self.positions_index(tags[form_index])
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

      MISSING_MSG = "!MISSING!"

      # Returns pretty string representation of the paradigm.
      # If +forms+ are given, they are prepend to the the paradigm
      # inflection table. The +forms+ have to be in the order
      # of paradigms suffixes.
      def pretty_to_s(forms=nil)
        if forms
          max1 = forms.map{|f| f && f.size}.compact.max + 1
          max1 = MISSING_MSG.size if MISSING_MSG.size > max1
          max2 = self.suffixes.map{|s| s.size}.max + 1
          self.mapping(:type => :long).map.with_index do |mapping,index|
            form = self.form_position[index] && forms[self.form_position[index]]
            form = form.nil? ? MISSING_MSG : form
            sprintf("%-#{max1}s%#{max2}s  %s",form,mapping[0],mapping[1..-1].join(":"))
          end.join("\n")
        else
          raise "TODO implement"
        end
      end

      # Returns the index of paradigm's suffix for given flexemic +positions+.
      # The tags in each of the flexemic positions have to be sorted.
      # TODO #1
      def positions_index(positions)
        index = self.mapping(:type => :canonical).each.
          with_index do |suffix_with_position,suffix_index|
          suffix_position = suffix_with_position[1]
          # TODO #6 optimize
          if positions.size == suffix_position.size &&
            positions.all?{|tags| suffix_position.include?(tags)}
            break suffix_index
          end
        end
        index.is_a?(Fixnum) ? index : nil
      end

      # Returns the index of paradigm's suffix for given flexemic +position+
      # (unlike the in previous function - there should be only one array with symbols).
      # The tags have to be sorted.
      def position_index(position)
        index = self.mapping(:type => :canonical).each.
          with_index do |suffix_with_position,suffix_index|
          suffix_position = suffix_with_position[1]
          if position.size == suffix_position.first.size &&
            suffix_position.include?(position)
            break suffix_index
          end
        end
        index.is_a?(Fixnum) ? index : nil
      end

      class << self
        # Tries to guess the inflection paradigm of the forms. If +type_tag+
        # is given, the results is less ambigious.
        #
        # Options:
        # * +:with_counts+ - returns the paradigms with statistics (+false+ by default)
        # * +:fuzzy+ - if +true+ allows for fuzzy matching (+false+ by default)
        # * +:tags+ - an optional array of tags corresponding to +forms+; if
        #   present they are strictly matched against the paradigm. This have
        #   important impact on performance but allows for solving issues with
        #   ambiguous suffixes.
        def guess(forms,type_tag=nil,options={})
          forms = forms.uniq
          if options[:tags]
            # #5 use FlexemeType canonical order
            options[:tags] = options[:tags].map{|ts| ts.map{|t| t.sort}}
          end
          if type_tag
            paradigms = FlexemeType.for_tag(type_tag).paradigms
          else
            paradigms = self.each
          end
          best_value = -1
          result = paradigms.select do |paradigm|
            next if paradigm.nil?
            next if paradigm.suffixes.nil?
            if options[:fuzzy]
              paradigm.suffixes.size >= forms.size
            else
              paradigm.suffixes.size == forms.size
            end
          end.map do |paradigm|
            matched = {}
            matched_count = 0
            matchers_size = nil
            suffix_matcher = paradigm.suffix_matcher
            forms.each.with_index do |form,form_index|
              match = nil
              index = nil
              if options[:tags]
                matchers_size = paradigm.suffixes.size
                index = paradigm.positions_index(options[:tags][form_index])
                if index
                  match_data = /(#{paradigm.suffixes[index]})$/.match(form)
                  if match_data
                    match = match_data[0]
                  end
                end
              else
                match_data = suffix_matcher.match(form)
                if match_data
                  match,index = match_data.captures.each.with_index{|c,i| break [c,i] if c}
                  matchers_size ||= match_data.captures.size
                end
              end
              if match
                matched_count += match.size
                matched[index] = true
              end
            end
            [paradigm,matched.size,matchers_size,matched_count]
          end.select do|paradigm,matched_s,matchers_s,matched_c|
            if options[:fuzzy]
              matched_s > 0
              #matched_s >= forms.size
            else
              matched_s == forms.size
            end
          end.sort_by do |paradigm,matched_s,matchers_s,matched_c|
            if options[:fuzzy]
              - matched_c.to_f * 0.001 - matched_s.to_f / matchers_s
            else
              - matched_c * matched_s
            end
          end.select do |paradigm,matched_s,matchers_s,matched_c|
            unless options[:fuzzy]
              matched_value = matched_c * matched_s
              best_value = matched_value if best_value < matched_value
              best_value == matched_value
            else
              true
            end
          end
          unless options[:with_counts]
            result.map!{|p,i1,i2,i3| p}
          end
          result
        end

        # A multi-level guess. The primary difference with +guess+ is that
        # the result is always an array containing pairs: [paradigms, forms]
        # and as such it might return multiple results (still each pair might
        # be ambiguous. The second difference is that is uses a set of methods,
        # each more complicated and slower than the previous, but capable
        # of solving harder issues.
        #
        # The methods are as follows:
        # * trivial cases (flexeme type with one paradigm with one suffix)
        # * guess without tags
        # * guess with tags
        # * guess with detection of ambiguous 'inflection position' -> 'form'
        #   mappings and heuristic split of forms
        # * guess with detection of ambiguous mappings and exploration of
        #   all ambiguous inflection positions' combinations
        def multiguess(forms,type,tags,gender=nil)
          # 0) trivial cases
          type = Rlp::Grammar::FlexemeType.for_tag(type.to_sym)
          if type.paradigms.size == 1 && type.paradigms.first.suffixes.size == 1
            return forms.map{|f| [type.paradigms.to_a,[f],tags]}
          end
          # 1) guess without tags
          paradigms = Rlp::Grammar::Paradigm.guess(forms,type.to_sym)
          unless paradigms.empty?
            disambiguated = disambiguate(paradigms,gender)
            if disambiguated.size == 1
              return [[disambiguated,forms,tags]]
            end
          end
          # 2) guess with tags
          paradigms = Rlp::Grammar::Paradigm.guess(forms,type.to_sym,
                                                   :tags => tags)
          unless paradigms.empty?
            return [[disambiguate(paradigms,gender),forms,tags]]
          end
          # build 'inflection postion' -> 'forms' map
          position_to_forms = {}
          forms.zip(tags).each do |form,form_tags|
            form_tags.uniq.each do |current_tags|
              position_to_forms[current_tags] ||= []
              position_to_forms[current_tags] << form
            end
          end
          # There are no ambiguous position -> form mappings,
          # the paradigm is unknown.
          unless position_to_forms.values.any?{|fs|  fs.size > 1}
            return [[[],forms,tags]]
          end
          #position_to_forms.values.each{|fs| ambiguity[fs.size] += 1}
          position_to_forms = position_to_forms.sort_by{|t,fs| fs.size}
          # in most cases there are only two competing flexemes
          if position_to_forms.last[1].size == 2
            # 3) split the forms heuristically into two flexemes
            #    by taking the last to forms and looking for the
            #    longest common substring
            ambig_flexemes = position_to_forms.last[1].
              map{|f| [[position_to_forms.last[0]],[f]]}
            position_to_forms[0..-2].each do |position,position_forms|
              if position_forms.size == 2
                map = {}
                2.times.map do |flexeme_index|
                  position_forms.each.with_index do |form,form_index|
                    d_index = ambig_flexemes[flexeme_index][1].first.chars.to_a.
                      zip(form.chars.to_a).each.with_index do |c1_c2,c_index|
                      break c_index if c1_c2[0] != c1_c2[1]
                    end
                    unless d_index.is_a?(Fixnum)
                      d_index = ambig_flexemes[flexeme_index][1].first.size
                    end
                    map[[flexeme_index,form_index]] = d_index - form.size
                  end
                end
                map = map.sort_by{|k,v| -v}
                # assign the best match (e.g. [1,0])...
                best_indices = map[0][0]
                ambig_flexemes[best_indices[0]][0] << position
                ambig_flexemes[best_indices[0]][1] << position_forms[best_indices[1]]
                # and the complementary match (e.g. [0,1])
                map[1..-1].each do |indices,value|
                  if indices[0] != best_indices[0] && indices[1] != best_indices[1]
                    ambig_flexemes[indices[0]][0] << position
                    ambig_flexemes[indices[0]][1] << position_forms[indices[1]]
                    break
                  end
                end
              else
                2.times{|i| ambig_flexemes[i][0] << position;
                  ambig_flexemes[i][1] << position_forms[0]}
              end
            end
            # re-create mappings 'form' -> 'positions', e.g.
            # transform the array
            ambig_flexemes.map! do |positions_and_forms|
              f_positions, f_forms = positions_and_forms
              map = {}
              f_positions.zip(f_forms).each do |position,form|
                map[form] ||= []
                map[form] << position
              end
              [map.keys,map.values]
            end
            paradigms = ambig_flexemes.map do |forms_and_positions|
              f_forms, f_positions = forms_and_positions
              self.guess(f_forms,type.to_sym,:tags => f_positions)
            end
            if paradigms.all?{|ps| !ps.empty?}
              return ambig_flexemes.zip(paradigms).
                map do |forms_and_positions,f_paradigms|
                f_forms, f_positions = forms_and_positions
                [disambiguate(f_paradigms,gender),f_forms,f_positions]
              end
            end
          end
          # 4) visit all mappings
          # # TODO
          #matched_sets = []
          #visit_mappings(position_to_forms,type,matched_sets)
          #unless matched_sets.empty?
          #  pp matched_sets.map{|e| [e[0].code,e[1]]}
          #end
          return [[[],forms,tags]]
        end

        protected
        def disambiguate(paradigms,gender)
          unless paradigms.first.gender.nil?
            paradigms = paradigms.select{|p| gender.to_sym == p.gender.tag}
          end
          paradigms
        end
      end
    end
  end
end
