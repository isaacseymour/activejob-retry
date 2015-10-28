require 'active_job'
require 'active_support'
require 'active_support/core_ext' # ActiveJob uses core exts, but doesn't require it
require 'active_job/retry/version'
require 'active_job/retry/errors'
require 'active_job/retry/constant_backoff_strategy'
require 'active_job/retry/variable_backoff_strategy'
require 'active_job/retry/exponential_backoff_strategy'

unless ActiveJob::Base.method_defined?(:deserialize)
  require 'active_job/retry/deserialize_monkey_patch'
end

module ActiveJob
  module Retry
    PROBLEMATIC_ADAPTERS = [
      'ActiveJob::QueueAdapters::InlineAdapter',
      'ActiveJob::QueueAdapters::QuAdapter',
      'ActiveJob::QueueAdapters::SneakersAdapter',
      'ActiveJob::QueueAdapters::SuckerPunchAdapter'
    ].freeze

    def self.included(base)
      if PROBLEMATIC_ADAPTERS.include?(ActiveJob::Base.queue_adapter.name)
        warn("#{ActiveJob::Base.queue_adapter.name} does not support delayed retries, " \
             'so does not work with ActiveJob::Retry. You may experience strange ' \
             'behaviour.')
      end

      base.extend(ClassMethods)
    end

    #################
    # Configuration #
    #################

    module ClassMethods
      attr_reader :backoff_strategy

      def constant_retry(options)
        retry_with(ConstantBackoffStrategy.new(options))
      end

      def variable_retry(options)
        retry_with(VariableBackoffStrategy.new(options))
      end

      def exponential_retry(options)
        retry_with(ExponentialBackoffStrategy.new(options))
      end

      def retry_with(backoff_strategy)
        unless backoff_strategy_valid?(backoff_strategy)
          raise InvalidConfigurationError,
                'Backoff strategies must define `should_retry?(attempt, exception)`, ' \
                'and `retry_delay(attempt, exception)`.'
        end

        @backoff_strategy = backoff_strategy
      end

      def backoff_strategy_valid?(backoff_strategy)
        backoff_strategy.respond_to?(:should_retry?) &&
          backoff_strategy.respond_to?(:retry_delay) &&
          backoff_strategy.method(:should_retry?).arity == 2 &&
          backoff_strategy.method(:retry_delay).arity == 2
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

    # Override `rescue_with_handler` to make sure our catch is before callbacks,
    # so `rescue_from`s will only be run after any retry attempts have been exhausted.
    def rescue_with_handler(exception)
      unless self.class.backoff_strategy.should_retry?(retry_attempt, exception)
        return super
      end

      this_delay = self.class.backoff_strategy.retry_delay(retry_attempt, exception)
      # TODO: This breaks DelayedJob and Resque for some weird ActiveSupport reason.
      # logger.info("Retrying (attempt #{retry_attempt + 1}, waiting #{this_delay}s)")
      @retry_attempt += 1
      retry_job(wait: this_delay)

      true # Exception has been handled
    end
  end
end
