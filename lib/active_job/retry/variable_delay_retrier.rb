require 'active_job/retry/fixed_delay_retrier'
require 'active_job/retry/variable_options_validator'

module ActiveJob
  module Retry
    class VariableDelayRetrier < FixedDelayRetrier
      def initialize(options)
        super(options)
        VariableOptionsValidator.new(options).validate!
        @retry_limit        ||= options.fetch(:strategy).length
        @backoff_strategy     = options.fetch(:strategy)
        @min_delay_multiplier = options.fetch(:min_delay_multiplier, 1.0)
        @max_delay_multiplier = options.fetch(:max_delay_multiplier, 1.0)
        @fatal_exceptions     = options.fetch(:fatal_exceptions, [])
        @retry_exceptions     = options.fetch(:retry_exceptions, nil)
      end

      def retry_delay(attempt, _)
        (backoff_strategy[attempt] * delay_multiplier).to_i
      end

      private

      attr_reader :backoff_strategy, :min_delay_multiplier, :max_delay_multiplier

      def random_delay?
        min_delay_multiplier != max_delay_multiplier
      end

      def delay_multiplier
        return max_delay_multiplier unless random_delay?
        rand(min_delay_multiplier..max_delay_multiplier)
      end
    end
  end
end
