require 'active_job/retry/constant_options_validator'

module ActiveJob
  class Retry < Module
    class ConstantBackoffStrategy
      def initialize(options)
        ConstantOptionsValidator.new(options).validate!
        @retry_limit          = options.fetch(:limit, 1)
        @retry_delay          = options.fetch(:delay, 0)
        @fatal_exceptions     = options.fetch(:fatal_exceptions, [])
        @retryable_exceptions = options.fetch(:retryable_exceptions, nil)
      end

      def should_retry?(attempt, exception)
        return false if retry_limit_reached?(attempt)
        return false unless retryable_exception?(exception)
        true
      end

      def retry_delay(_attempt, _exception)
        @retry_delay
      end

      private

      attr_reader :retry_limit, :fatal_exceptions, :retryable_exceptions

      def retry_limit_reached?(attempt)
        return false unless retry_limit
        attempt >= retry_limit
      end

      def retryable_exception?(exception)
        if retryable_exceptions.nil?
          !exception_blacklisted?(exception)
        else
          exception_whitelisted?(exception)
        end
      end

      def exception_whitelisted?(exception)
        retryable_exceptions.any? { |ex| exception.is_a?(ex) }
      end

      def exception_blacklisted?(exception)
        fatal_exceptions.any? { |ex| exception.is_a?(ex) }
      end
    end
  end
end
