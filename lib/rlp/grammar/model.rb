require 'rod'
require 'rlp/grammar/client'

module Rlp
  module Grammar
    # The base class for Rlp data oriented classes.
    class Model < Rod::Model
      database_class Client
    end
  end
end
