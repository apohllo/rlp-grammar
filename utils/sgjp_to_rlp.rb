module Rlp
  module Utils
    def self.map_tags(tags)
      groups = tags.split("|")
      groups.map do |group|
        group.split(":").map do |tag|
          case tag
          when 'pos'
            'posit'
          when /^(neg|aff|praep|npraep|agl|nagl)$/
            nil
          when 'com'
            'comp'
          else
            tag
          end
        end.compact
      end
    end
  end
end
