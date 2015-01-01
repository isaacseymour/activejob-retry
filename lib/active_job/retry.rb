module ActiveJob
  module Retry
    class UnsupportedAdapterError < StandardError; end
    SUPPORTED_ADAPTERS = %i(backburner delayed_job que resque sidekiq).freeze

    # If you want your job to retry on failure, simply include this module in your class,
    #
    #   class DeliverWebHook < ActiveJob::Base
    #     include ActiveJob::Retry
    #     queue_as :web_hooks
    #
    #     retry_with limit: 8,                         # default 1
    #                delay: 60,                        # default 0
    #                fatal_exceptions: [RuntimeError], # default [], i.e. none
    #                retry_exceptions: [TimeoutError]  # default nil, i.e. all
    #
    #     def perform(url, web_hook_id, hmac_key)
    #       work!
    #     end
    #   end
    def self.included(base)
      # This breaks all specs because the adapter gets set after class eval :(
      # unless SUPPORTED_ADAPTERS.include?(ActiveJob::Base.queue_adapter)
      #   raise UnsupportedAdapterError,
      #         "Only Backburner, DelayedJob, Que, Resque, and Sidekiq support delayed " \
      #         "retries. #{ActiveJob::Base.queue_adapter} is not supported."
      # end

      base.extend(ClassMethods)
    end

    module ClassMethods
      # Setup DSL
      def retry_with(options)
        OptionsValidator.new(options).validate!

        @retry_limit      = options[:limit]            if options[:limit]
        @retry_delay      = options[:delay]            if options[:delay]
        @fatal_exceptions = options[:fatal_exceptions] if options[:fatal_exceptions]
        @retry_exceptions = options[:retry_exceptions] if options[:retry_exceptions]
      end

      ############
      # Defaults #
      ############
      def retry_limit
        @retry_limit ||= 1
      end

      def retry_delay
        @retry_delay ||= 0
      end

      def fatal_exceptions
        @fatal_exceptions ||= []
      end

      def retry_exceptions
        @retry_exceptions ||= nil
      end

      #################
      # Retry helpers #
      #################
      def retry_exception?(exception)
        return true if retry_exceptions.nil? && fatal_exceptions.empty?
        return exception_whitelisted?(exception) unless retry_exceptions.nil?
        !exception_blacklisted?(exception)
      end

      def exception_whitelisted?(exception)
        retry_exceptions.any? { |ex| exception.is_a?(ex) }
      end

      def exception_blacklisted?(exception)
        fatal_exceptions.any? { |ex| exception.is_a?(ex) }
      end
    end

    #############
    # Overrides #
    #############
    def serialize
      super.merge('retry_attempt' => retry_attempt + 1)
    end

    def deserialize(job_data)
      super(job_data)
      @retry_attempt = job_data['retry_attempt']
    end

    # Override `rescue_with_handler` to make sure our catch is the last one, and doesn't
    # happen if the exception has already been caught in a `rescue_from`
    def rescue_with_handler(exception)
      super || retry_or_reraise(exception)
    end

    ##################
    # Retrying logic #
    ##################
    def retry_attempt
      @retry_attempt ||= 0
    end

    # Override me if you want more complex behaviour
    def retry_delay
      self.class.retry_delay
    end

    def should_retry?(exception)
      return false if retry_limit_reached?
      return false unless self.class.retry_exception?(exception)
      true
    end

    def retry_limit_reached?
      return true if self.class.retry_limit == 0
      return false if self.class.retry_limit == -1
      retry_attempt >= self.class.retry_limit
    end

    def retry_or_reraise(exception)
      raise exception unless should_retry?(exception)

      this_delay = retry_delay
      # This breaks DelayedJob and Resque for some weird ActiveSupport reason.
      # logger.log(Logger::INFO, "Retrying (attempt #{retry_attempt + 1}, waiting #{this_delay}s)")
      retry_job(wait: this_delay)
    end
  end
end
