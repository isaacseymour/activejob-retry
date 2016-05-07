require_relative '../support/job_buffer'

class GidJob < ActiveJob::Base
  include ActiveJob::Retry.new(strategy: :constant)

  def perform(person)
    JobBuffer.add("Person with ID: #{person.id}")
  end
end

