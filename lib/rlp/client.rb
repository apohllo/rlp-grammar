require 'rod'

module Rlp
  # The client class is an abstraction over the data storage facility.
  class Client < Rod::Database
    attr_accessor :encoding

  end
end
