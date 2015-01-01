class NestedJob < ActiveJob::Base
  include ActiveJob::Retry

  def perform
    LoggingJob.perform_later "NestedJob"
  end

  def job_id
    "NESTED-JOB-ID"
  end
end

