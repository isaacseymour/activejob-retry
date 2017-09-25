require 'active_job/retry/errors'

module ActiveJob
  class Retry < Module
    class VariableOptionsValidator
      DELAY_MULTIPLIER_KEYS = %i[min_delay_multiplier max_delay_multiplier].freeze

      def initialize(options)
        @options = options
      end

      def validate!
        validate_banned_basic_option!(:limit)
        validate_banned_basic_option!(:delay)
        validate_delays!
        validate_delay_multipliers!
      end

      private

      attr_reader :options, :retry_limit

      def validate_banned_basic_option!(key)
        return unless options[key]

        raise InvalidConfigurationError, "Cannot use #{key} with VariableBackoffStrategy"
      end

      def validate_delays!
        return if options[:delays]

        raise InvalidConfigurationError,
              'You must define an array of delays between attempts'
      end

      def validate_delay_multipliers!
        validate_delay_multipliers_supplied_together!

        return unless options[:min_delay_multiplier] && options[:max_delay_multiplier]

        return if options[:min_delay_multiplier] <= options[:max_delay_multiplier]

        raise InvalidConfigurationError,
              'min_delay_multiplier must be less than or equal to max_delay_multiplier'
      end

      def validate_delay_multipliers_supplied_together!
        supplied = DELAY_MULTIPLIER_KEYS.map { |key| options.key?(key) }
        return if supplied.none? || supplied.all?

        raise InvalidConfigurationError,
              'If one of min/max_delay_multiplier is supplied, both are required'
      end
    end
  end
end
