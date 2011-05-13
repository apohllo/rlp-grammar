module Rlp
  # The base class of all Rlp exceptions.
  class RlpException < Exception
  end

  # This exception is raised when an abstract method is called.
  class AbstractMethod < RlpException
    def initialize(klass,name)
      @class = klass
      @name = name
    end

    def to_s
      "Abstract method '#{@name}' called for #{@class}"
    end
  end
end
