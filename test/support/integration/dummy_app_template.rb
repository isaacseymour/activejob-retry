if ENV['AJADAPTER'] == 'delayed_job'
  generate "delayed_job:active_record", "--quiet"
  rake("db:migrate")
end

initializer 'activejob.rb', <<-CODE
require "#{File.expand_path("../jobs_manager.rb",  __FILE__)}"
JobsManager.current_manager.setup
CODE

file 'app/jobs/test_job.rb', <<-CODE
class TestJob < ActiveJob::Base
  include ActiveJob::Retry

  queue_as :integration_tests
  retry_with limit: 2, delay: 3

  def perform(x, fail_first = false)
    raise "Failing first" if fail_first && retry_attempt == 1

    File.open(Rails.root.join("tmp/\#{x}"), "w+") do |f|
      f.write x
    end
  end
end
CODE
