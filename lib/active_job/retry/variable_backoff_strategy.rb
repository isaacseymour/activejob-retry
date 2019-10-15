# frozen_string_literal: true

require 'active_job/retry/constant_backoff_strategy'
require 'active_job/retry/variable_options_validator'

module ActiveJob
  class Retry < Module
    class VariableBackoffStrategy < ConstantBackoffStrategy
      def initialize(options)
        super(options)
        VariableOptionsValidator.new(options).validate!
        @retry_limit          = options.fetch(:delays).length + 1
        @retry_delays         = options.fetch(:delays)
        @min_delay_multiplier = options.fetch(:min_delay_multiplier, 1.0)
        @max_delay_multiplier = options.fetch(:max_delay_multiplier, 1.0)
      end

      def retry_delay(attempt, _exception)
        (retry_delays[attempt - 1] * delay_multiplier).to_i
      end

      private

      attr_reader :retry_delays, :min_delay_multiplier, :max_delay_multiplier

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
