require 'active_job/retry/errors'

module ActiveJob
  module Retry
    class FixedOptionsValidator
      def initialize(options)
        @options = options
      end

      def validate!
        validate_limit_numericality!
        validate_infinite_limit!
        validate_delay!
        validate_not_both_exceptions!
        # Fatal exceptions must be an array (cannot be nil, since then all exceptions
        # would be fatal - for that just set `limit: 0`)
        validate_array_of_exceptions!(:fatal_exceptions)
        # Retry exceptions must be an array of exceptions or `nil` to retry any exception
        validate_array_of_exceptions!(:retry_exceptions) if options[:retry_exceptions]
      end

      private

      attr_reader :options

      # Limit must be an integer >= -1
      def validate_limit_numericality!
        return unless options[:limit]

        unless options[:limit].is_a?(Fixnum)
          raise InvalidConfigurationError, 'Limit must be an integer'
        end

        raise InvalidConfigurationError, 'Limit must be >= -1' if options[:limit] < -1
      end

      # If it is -1 you *must* set `infinite_job: true` and understand that you're
      # entering a world of pain and your ops team might hurt you.
      def validate_infinite_limit!
        return unless options[:limit] == -1 && options[:infinite_job].nil?
        raise InvalidConfigurationError,
              'You must set `infinite_job: true` to use an infinite job'
      end

      # Delay must be non-negative
      def validate_delay!
        return unless options[:delay]
        return if options[:delay] >= 0

        raise InvalidConfigurationError, 'Delay must be non-negative'
      end

      def validate_not_both_exceptions!
        return unless options[:fatal_exceptions] && options[:retry_exceptions]

        raise InvalidConfigurationError,
              'fatal_exceptions and retry_exceptions cannot be used together'
      end

      def validate_array_of_exceptions!(key)
        return unless options[key]
        if options[key].is_a?(Array) &&
           options[key].all? { |ex| ex.is_a?(Class) && ex <= Exception }
          return
        end

        raise InvalidConfigurationError, "#{key} must be an array of exceptions!"
      end
    end
  end
end
