module ActiveJob
  module Retry
    class ExponentialOptionsValidator
      DELAY_MULTIPLIER_KEYS = %i(min_delay_multiplier max_delay_multiplier).freeze

      def initialize(options, retry_limit)
        @options = options
        @retry_limit = retry_limit
      end

      def validate!
        validate_strategy!
        validate_delay_multipliers!
      end

      private

      attr_reader :options, :retry_limit

      def validate_strategy!
        unless options[:strategy]
          raise InvalidConfigurationError, "You must define a backoff strategy"
        end

        return unless retry_limit

        unless retry_limit > 0
          raise InvalidConfigurationError,
                "Exponential backoff cannot be used with infinite or no retries"
        end

        return if options[:strategy].length == retry_limit

        raise InvalidConfigurationError, "Strategy must have a delay for each retry"
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
        supplied = DELAY_MULTIPLIER_KEYS.map { |key| options.has?(key) }
        supplied.none? || supplied.all?
      end
    end
  end
end
