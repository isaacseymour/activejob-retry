# frozen_string_literal: true

require 'active_job/retry/constant_backoff_strategy'
require 'active_job/retry/variable_backoff_strategy'
require 'active_job/retry/exponential_backoff_strategy'

module ActiveJob
  class Retry < Module
    module Strategy
      def self.choose(strategy, options)
        case strategy
        when :constant    then ActiveJob::Retry::ConstantBackoffStrategy.new(options)
        when :variable    then ActiveJob::Retry::VariableBackoffStrategy.new(options)
        when :exponential then ActiveJob::Retry::ExponentialBackoffStrategy.new(options)
        else strategy
        end
      end
    end
  end
end
