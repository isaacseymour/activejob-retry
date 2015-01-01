require_relative '../support/job_buffer'

class GidJob < ActiveJob::Base
  include ActiveJob::Retry

  def perform(person)
    JobBuffer.add("Person with ID: #{person.id}")
  end
end

