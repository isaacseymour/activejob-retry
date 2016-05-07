require_relative '../support/job_buffer'

class HelloJob < ActiveJob::Base
  include ActiveJob::Retry.new(strategy: :constant)

  def perform(greeter = "David")
    JobBuffer.add("#{greeter} says hello")
  end
end
