require 'active_job/retry/exponential_options_validator'

module ActiveJob
  class Retry < Module
    class ExponentialBackoffStrategy < ConstantBackoffStrategy
      def initialize(options)
        ExponentialOptionsValidator.new(options).validate!
        @retry_limit          = options.fetch(:limit, 1)
        @fatal_exceptions     = options.fetch(:fatal_exceptions, [])
        @retryable_exceptions = options.fetch(:retryable_exceptions, nil)
      end

      def retry_delay(attempt, _exception)
        (attempt**4 + 15 + (rand(30) * (attempt + 1))).seconds
      end
    end
  end
end
