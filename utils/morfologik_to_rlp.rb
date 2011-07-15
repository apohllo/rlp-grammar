module Rlp
  module Utils
    def self.map_tags(tags)
      groups = tags.split("+")
      result = []
      groups.each do |group|
        tags = group.split(":")
        tags = tags.map do |tag|
          # TODO gender should be selected according to types_to_classes.txt
          case tag
          when "verb"
            nil
          else
            tag
          end.compact
        end
      end
      result
    end
  end
end
