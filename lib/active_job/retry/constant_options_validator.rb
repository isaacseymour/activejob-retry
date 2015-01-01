require 'active_job/retry/errors'

module ActiveJob
  module Retry
    class ConstantOptionsValidator
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
