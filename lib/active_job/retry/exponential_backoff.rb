module ActiveJob
  module Retry
    # If you want your job to retry on failure using a varying delay, simply
    # extend your class with this module:
    #
    #   class DeliverSMS < ActiveJob::Base
    #     extend ActiveJob::Retry::ExponentialBackoff
    #     queue_as :messages
    #
    #     def perform(mobile_number, message)
    #       SmsService.deliver!(mobile_number, message)
    #     end
    #   end
    #
    # Easily do something custom:
    #
    #   class DeliverSMS
    #     extend ActiveJob::Retry::ExponentialBackoff
    #     queue_as :messages
    #
    #     # Options from ActiveJob::Retry can also be used
    #     retry_with strategy: [0, 60], # retry immediately, then after 60 seconds
    #                min_delay_multiplier: 0.8, # multiply the delay by a random number
    #                max_delay_multiplier: 1.5  # between 0.8 and 1.5
    #
    #     def perform(mobile_number, message)
    #       SmsService.deliver!(mobile_number, message)
    #     end
    #   end
    #
    module ExponentialBackoff
      include ActiveJob::Retry

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        extend ActiveJob::Retry::ClassMethods

        # Setup DSL
        def retry_with(options)
          super(options)
          ExponentialOptionsValidator.new(options, retry_limit).validate!

          @backoff_strategy     = options[:strategy]             if options[:strategy]
          @min_delay_multiplier = options[:min_delay_multiplier] if options[:min_delay_multiplier]
          @max_delay_multiplier = options[:max_delay_multiplier] if options[:max_delay_multiplier]
        end

        ############
        # Defaults #
        ############
        def retry_limit
          @retry_limit ||= backoff_strategy.length
        end

        def backoff_strategy
          @backoff_strategy ||= nil
        end

        def min_delay_multiplier
          @min_delay_multiplier ||= 1.0
        end

        def max_delay_multiplier
          @max_delay_multiplier ||= 1.0
        end
      end

      ###############
      # Retry logic #
      ###############
      def retry_delay
        delay = backoff_strategy[retry_attempt]

        return (delay * max_delay_multiplier).to_i unless random_delay?

        (delay * rand(random_delay_range)).to_i
      end

      def random_delay?
        retry_delay_multiplicand_min != retry_delay_multiplicand_max
      end

      def random_delay_range
        min_delay_multiplier..max_delay_multiplier
      end
    end
  end
end
