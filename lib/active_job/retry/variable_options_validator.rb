require 'active_job/retry/errors'

module ActiveJob
  module Retry
    class VariableOptionsValidator
      DELAY_MULTIPLIER_KEYS = [:min_delay_multiplier, :max_delay_multiplier].freeze

      def initialize(options)
        @options = options
      end

      def validate!
        validate_banned_basic_options!
        validate_strategy!
        validate_delay_multipliers!
      end

      private

      attr_reader :options, :retry_limit

      def validate_banned_basic_options!
        if options[:limit]
          raise InvalidConfigurationError, "Cannot use limit with VariableDelayRetrier"
        end

        if options[:delay]
          raise InvalidConfigurationError, "Cannot use delay with VariableDelayRetrier"
        end
      end

      def validate_strategy!
        unless options[:strategy]
          raise InvalidConfigurationError, "You must define a backoff strategy"
        end
      end

      def validate_delay_multipliers!
        unless both_or_neither_multiplier_supplied?
          raise InvalidConfigurationError,
                "If one of min/max_delay_multiplier is supplied, both are required"
        end

        return unless options[:min_delay_multiplier] && options[:max_delay_multiplier]

        return if options[:min_delay_multiplier] <= options[:max_delay_multiplier]

        raise InvalidConfigurationError,
              "min_delay_multiplier must be less than or equal to max_delay_multiplier"
      end

      def both_or_neither_multiplier_supplied?
        supplied = DELAY_MULTIPLIER_KEYS.map { |key| options.key?(key) }
        supplied.none? || supplied.all?
      end
    end
  end
end
