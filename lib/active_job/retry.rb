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

def choose_strategy(strategy, options)
  case strategy
  when :constant    then ActiveJob::Retry::ConstantBackoffStrategy.new(options)
  when :variable    then ActiveJob::Retry::VariableBackoffStrategy.new(options)
  when :exponential then ActiveJob::Retry::ExponentialBackoffStrategy.new(options)
  else strategy
  end
end

module ActiveJob
  class Retry < Module
    PROBLEMATIC_ADAPTERS = [
      'ActiveJob::QueueAdapters::InlineAdapter',
      'ActiveJob::QueueAdapters::QuAdapter',
      'ActiveJob::QueueAdapters::SneakersAdapter',
      'ActiveJob::QueueAdapters::SuckerPunchAdapter'
    ].freeze

    #################
    # Configuration #
    #################
    def initialize(strategy: nil, callback: nil, **options)
      check_adapter!
      @backoff_strategy = choose_strategy(strategy, options)
      @retry_callback = callback

      validate_params
    end

    def included(base)
      klass = self
      base.define_singleton_method(:inherited) do |subclass|
        subclass.send(:include, klass)
      end
      define_backoff_strategy(base)
      define_retry_attempt_tracking(base)
      define_retry_method(base)
      define_retry_logic(base)
      define_retry_callback(base)
    end

    private

    attr_reader :backoff_strategy, :retry_callback

    def define_backoff_strategy(klass)
      klass.instance_variable_set(:@backoff_strategy, @backoff_strategy)
      klass.define_singleton_method(:backoff_strategy) { @backoff_strategy }
    end

    def define_retry_attempt_tracking(klass)
      klass.instance_eval do
        define_method(:serialize) do |*args|
          super(*args).merge('retry_attempt' => retry_attempt)
        end
        define_method :deserialize do |job_data|
          super(job_data)
          @retry_attempt = job_data['retry_attempt']
        end
        define_method(:retry_attempt) { @retry_attempt ||= 1 }
      end
    end

    def define_retry_method(klass)
      klass.instance_eval do
        define_method :internal_retry do |exception|
          this_delay = self.class.backoff_strategy.retry_delay(retry_attempt, exception)

          cb = self.class.retry_callback &&
               instance_exec(exception, this_delay, &self.class.retry_callback)
          return if cb == :halt

          # TODO: This breaks DelayedJob and Resque for some weird ActiveSupport reason.
          # logger.info("Retrying (attempt #{retry_attempt + 1}, waiting #{this_delay}s)")
          @retry_attempt += 1
          retry_job(wait: this_delay)
        end
      end
    end

    def define_retry_logic(klass)
      klass.instance_eval do
        # Override `rescue_with_handler` to make sure our catch is before callbacks,
        # so `rescue_from`s will only be run after any retry attempts have been exhausted.
        define_method :rescue_with_handler do |exception|
          if self.class.backoff_strategy.should_retry?(retry_attempt, exception)
            internal_retry(exception)
            return true # Exception has been handled
          else
            return super(exception)
          end
        end
      end
    end

    def define_retry_callback(klass)
      klass.instance_variable_set(:@retry_callback, @retry_callback)
      klass.define_singleton_method(:retry_callback) { @retry_callback }
    end

    def check_adapter!
      adapter = ActiveJob::Base.queue_adapter
      adapter_name =
        case adapter
        when Class then adapter.name
        else adapter.class.name
        end

      if PROBLEMATIC_ADAPTERS.include?(adapter_name)
        warn("#{adapter_name} does not support delayed retries, so does not work with " \
             'ActiveJob::Retry. You may experience strange behaviour.')
      end
    end

    def validate_params
      if retry_callback && !retry_callback.is_a?(Proc)
        raise InvalidConfigurationError, 'Callback must be a `Proc`'
      end

      unless backoff_strategy_valid?
        raise InvalidConfigurationError,
              'Backoff strategies must define `should_retry?(attempt, exception)`, ' \
              'and `retry_delay(attempt, exception)`.'
      end
    end

    def backoff_strategy_valid?
      backoff_strategy.respond_to?(:should_retry?) &&
        backoff_strategy.respond_to?(:retry_delay) &&
        backoff_strategy.method(:should_retry?).arity == 2 &&
        backoff_strategy.method(:retry_delay).arity == 2
    end
  end
end
