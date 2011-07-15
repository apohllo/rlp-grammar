module Rlp
  module Grammar
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

    # This exception is raised when argument for a method call is invalid.
    class InvalidArgument < RlpException
      attr_reader :klass, :method, :value
      def initialize(klass,method,value)
        @klass = klass
        @method = method
        @value = value
      end

      def to_s
        "Invalid argument '#{@value}' for #{@klass}##{@method}"
      end
    end
  end
end
