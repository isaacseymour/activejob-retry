require 'bundler'
Bundler.setup

require 'active_job'
require 'support/job_buffer'

GlobalID.app = 'aj'

@adapter  = ENV['AJADAPTER'] || 'resque'

if ENV['AJ_INTEGRATION_TESTS']
  require 'support/integration/helper'
else
  require "adapters/#{@adapter}"
end

require 'active_job-retry'

require 'active_support/testing/autorun'

ActiveSupport::TestCase.test_order = :random
