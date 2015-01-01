require 'bundler'
Bundler.setup

require 'active_job'
require 'active_job-retry'
require 'support/job_buffer'

require 'pry'
GlobalID.app = 'aj'

@adapter  = ENV['AJADAPTER'] || 'inline'

def sidekiq?
  @adapter == 'sidekiq'
end

def ruby_193?
  RUBY_VERSION == '1.9.3' && RUBY_ENGINE != 'java'
end

# Sidekiq doesn't work with MRI 1.9.3
exit if sidekiq? && ruby_193?

if ENV['AJ_INTEGRATION_TESTS']
  require 'support/integration/helper'
else
  require "adapters/#{@adapter}"
end

require 'active_support/testing/autorun'

ActiveSupport::TestCase.test_order = :random
