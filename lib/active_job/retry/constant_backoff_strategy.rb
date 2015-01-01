require 'active_job/retry/constant_options_validator'

module ActiveJob
  module Retry
    class ConstantBackoffStrategy
      def initialize(options)
        ConstantOptionsValidator.new(options).validate!
        @retry_limit      = options.fetch(:limit, 1)
        @retry_delay      = options.fetch(:delay, 0)
        @fatal_exceptions = options.fetch(:fatal_exceptions, [])
        @retry_exceptions = options.fetch(:retry_exceptions, nil)
      end

      def should_retry?(attempt, exception)
        return false if retry_limit_reached?(attempt)
        return false unless retry_exception?(exception)
        true
      end

      def retry_delay(_attempt, _exception)
        @retry_delay
      end

      private

      attr_reader :retry_limit, :fatal_exceptions, :retry_exceptions

      def retry_limit_reached?(attempt)
        return false if retry_limit == -1
        attempt >= retry_limit
      end

      def retry_exception?(exception)
        if retry_exceptions.nil?
          !exception_blacklisted?(exception)
        else
          exception_whitelisted?(exception)
        end
      end

      def exception_whitelisted?(exception)
        retry_exceptions.any? { |ex| exception.is_a?(ex) }
      end

      def exception_blacklisted?(exception)
        fatal_exceptions.any? { |ex| exception.is_a?(ex) }
      end
    end
  end
end
