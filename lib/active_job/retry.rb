require 'active_job'
require 'active_support'
require 'active_support/core_ext' # ActiveJob uses core exts, but doesn't require it
require 'active_job/retry/version'
require 'active_job/retry/errors'
require 'active_job/retry/fixed_delay_retrier'
require 'active_job/retry/variable_delay_retrier'

unless ActiveJob::Base.method_defined?(:deserialize)
  require 'active_job/retry/deserialize_monkey_patch'
end

module ActiveJob
  module Retry
    SUPPORTED_ADAPTERS = [
      'ActiveJob::QueueAdapters::BackburnerAdapter',
      'ActiveJob::QueueAdapters::DelayedJobAdapter',
      'ActiveJob::QueueAdapters::ResqueAdapter',
      'ActiveJob::QueueAdapters::QueAdapter'
    ].freeze

    def self.included(base)
      unless SUPPORTED_ADAPTERS.include?(ActiveJob::Base.queue_adapter.to_s)
        raise UnsupportedAdapterError,
              "Only Backburner, DelayedJob, Que, and Resque support delayed " \
              "retries. #{ActiveJob::Base.queue_adapter} is not supported."
      end

      base.extend(ClassMethods)
    end

    #################
    # Configuration #
    #################

    module ClassMethods
      attr_reader :retrier

      def fixed_retry(options)
        retry_with(FixedDelayRetrier.new(options))
      end

      def variable_retry(options)
        retry_with(VariableDelayRetrier.new(options))
      end

      def retry_with(retrier)
        unless retrier_valid?(retrier)
          raise InvalidConfigurationError,
                "Retriers must define `should_retry?(attempt, exception)`, and " \
                "`retry_delay(attempt, exception)`."
        end

        @retrier = retrier
      end

      def retrier_valid?(retrier)
        retrier.respond_to?(:should_retry?) &&
          retrier.respond_to?(:retry_delay) &&
          retrier.method(:should_retry?).arity == 2 &&
          retrier.method(:retry_delay).arity == 2
      end
    end

    #############################
    # Storage of attempt number #
    #############################

    def serialize
      super.merge('retry_attempt' => retry_attempt)
    end

    def deserialize(job_data)
      super(job_data)
      @retry_attempt = job_data['retry_attempt']
    end

    def retry_attempt
      @retry_attempt ||= 1
    end

    ##########################
    # Performing the retries #
    ##########################

    # Override `rescue_with_handler` to make sure our catch is the last one, and doesn't
    # happen if the exception has already been caught in a `rescue_from`
    def rescue_with_handler(exception)
      super || retry_or_reraise(exception)
    end

    private

    def retry_or_reraise(exception)
      raise exception unless self.class.retrier.should_retry?(retry_attempt, exception)

      this_delay = self.class.retrier.retry_delay(retry_attempt, exception)
      # TODO This breaks DelayedJob and Resque for some weird ActiveSupport reason.
      # logger.log(Logger::INFO, "Retrying (attempt #{retry_attempt + 1}, waiting #{this_delay}s)")
      @retry_attempt += 1
      retry_job(wait: this_delay)

      true # Exception has been handled
    end
  end
end
