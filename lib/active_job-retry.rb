require 'active_job'
require 'active_support'

require 'active_job/retry'
require 'active_job/retry/exponential_backoff'
require 'active_job/retry/invalid_configuration_error'
require 'active_job/retry/options_validator'
require 'active_job/retry/exponential_options_validator'

require 'active_job/retry/version'

unless ActiveJob::Base.method_defined?(:deserialize)
  require 'active_job/retry/deserialize_monkey_patch'
end
