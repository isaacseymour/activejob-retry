rake("db:create")

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
  include ActiveJob::Retry.new(strategy: :constant)

  queue_as :integration_tests
  constant_retry limit: 2, delay: 3

  rescue_from(RuntimeError) do |e|
    if arguments[3]
      write_to_rescue_file
    else
      raise e
    end
  end

  def perform(x, fail_first = false, fail_always = false, rescue_file = false)
    raise "Failing first" if fail_first && retry_attempt == 1
    raise "Failing always" if fail_always

    File.open(Rails.root.join("tmp/\#{x}"), "w+") do |f|
      f.write x
    end
  end

  def write_to_rescue_file
    File.open(Rails.root.join("tmp/\#{arguments.first}_rescue"), "w+") do |f|
      f.write arguments.first
    end
  end
end
CODE
