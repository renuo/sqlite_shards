# frozen_string_literal: true

require "delegate"

module SqliteShards
  # A relation or record whose every call runs inside its database; what those calls return is bound the same way.
  class Bound < Delegator
    def initialize(object, &connect)
      super(object)
      @connect = connect
    end

    def __getobj__ = @object

    def __setobj__(object)
      @object = object
    end

    def method_missing(name, *args, **kwargs, &block)
      @connect.call { bind(@object.public_send(name, *args, **kwargs, &block)) }
    end

    def respond_to_missing?(name, include_private = false) = @object.respond_to?(name, include_private)

    def ==(other)
      @object == (other.is_a?(Bound) ? other.__getobj__ : other)
    end

    private

    def bind(result)
      case result
      when ::ActiveRecord::Relation, ::ActiveRecord::Base then Bound.new(result, &@connect)
      when ::Array then result.map { |element| bind(element) }
      else result
      end
    end
  end
end
