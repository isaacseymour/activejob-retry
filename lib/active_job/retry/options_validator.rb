module ActiveJob
  module Retry
     class OptionsValidator
      def initialize(options)
        @options = options
      end

      def validate!
        validate_limit!
        validate_delay!
        validate_fatal_exceptions!
        validate_retry_exceptions!
      end

      private

      attr_reader :options

      # Limit must be an integer >= -1
      # If it is -1 you *must* set `infinite_job: true` and understand that you're
      # entering a world of pain and your ops team might hurt you.
      def validate_limit!
        return unless options[:limit]

        unless options[:limit].is_a?(Fixnum)
          raise InvalidConfigurationError, "Limit must be an integer"
        end

        raise InvalidConfigurationError, "Limit must be >= -1" if options[:limit] < -1

        if options[:limit] == -1 && !options[:infinite_job]
          raise InvalidConfigurationError,
                "You must set `infinite_job: true` to use an infinite job"
        end
      end

      # Delay must be non-negative
      def validate_delay!
        return unless options[:delay]

        unless options[:delay] >= 0
          raise InvalidConfigurationError, "Delay must be non-negative"
        end
      end

      # Fatal exceptions must be an array (cannot be nil, since then all exceptions would
      # be fatal - for that just set `limit: 0`)
      def validate_fatal_exceptions!
        return unless options[:fatal_exceptions]

        unless options[:retry_exceptions].nil?
          raise InvalidConfigurationError,
                "fatal_exceptions and retry_exceptions cannot be used together"
        end

        unless options[:fatal_exceptions].is_a?(Array)
          raise InvalidConfigurationError, "fatal_exceptions must be an array"
        end

        unless options[:fatal_exceptions].all? { |ex| ex.is_a?(Class) && ex <= Exception }
          raise InvalidConfigurationError, "fatal_exceptions must be exceptions!"
        end
      end

      # Retry exceptions must be an array of exceptions or `nil` to retry any exception
      def validate_retry_exceptions!
        return unless options[:retry_exceptions]

        unless options[:fatal_exceptions].nil?
          raise InvalidConfigurationError,
                "retry_exceptions and fatal_exceptions cannot be used together"
        end

        unless options[:retry_exceptions].is_a?(Array)
          raise InvalidConfigurationError, "retry_exceptions must be an array or nil"
        end

        unless options[:retry_exceptions].all? { |ex| ex.is_a?(Class) && ex <= Exception }
          raise InvalidConfigurationError, "retry_exceptions must be exceptions!"
        end
      end
    end
  end
end
