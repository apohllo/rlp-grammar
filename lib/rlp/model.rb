require 'rod'
require 'rlp/client'

module Rlp
  # The base class for Rlp data oriented classes.
  class Model < Rod::Model
    database_class Client
  end
end
