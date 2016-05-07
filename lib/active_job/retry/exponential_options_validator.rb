require 'active_job/retry/errors'

module ActiveJob
  class Retry < Module
    class ExponentialOptionsValidator
      def initialize(options)
        @options = options
      end

      def validate!
        validate_limit_numericality!
        validate_infinite_limit!
        validate_delay_not_specified!
        validate_not_both_exceptions!
        # Fatal exceptions must be an array (cannot be nil, since then all
        # exceptions would be fatal - for that just set `limit: 0`)
        validate_array_of_exceptions!(:fatal_exceptions)
        # Retryable exceptions must be an array of exceptions or `nil` to retry
        # any exception
        if options[:retryable_exceptions]
          validate_array_of_exceptions!(:retryable_exceptions)
        end
      end

      private

      attr_reader :options

      # Limit must be an integer >= 0, or nil
      def validate_limit_numericality!
        return unless options[:limit]
        return if options[:limit].is_a?(Fixnum) && options[:limit] >= 0

        raise InvalidConfigurationError,
              'Limit must be an integer >= 0, or nil for unlimited retries'
      end

      # If no limit is supplied, you *must* set `unlimited_retries: true` and
      # understand that your ops team might hurt you.
      def validate_infinite_limit!
        limit = options.fetch(:limit, 1)
        return unless limit.nil? ^ options[:unlimited_retries] == true

        if limit.nil? && options[:unlimited_retries] != true
          raise InvalidConfigurationError,
                'You must set `unlimited_retries: true` to use `limit: nil`'
        else
          raise InvalidConfigurationError,
                'You must set `limit: nil` to have unlimited retries'
        end
      end

      # Delay must not be set
      def validate_delay_not_specified!
        return unless options[:delay]

        raise InvalidConfigurationError,
              'You can`t set delay for ExponentialBackoffStrategy'
      end

      def validate_not_both_exceptions!
        return unless options[:fatal_exceptions] && options[:retryable_exceptions]

        raise InvalidConfigurationError,
              'fatal_exceptions and retryable_exceptions cannot be used together'
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
