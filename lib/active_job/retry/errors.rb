module ActiveJob
  module Retry
    class InvalidConfigurationError < StandardError; end
    class UnsupportedAdapterError < StandardError; end
  end
end
