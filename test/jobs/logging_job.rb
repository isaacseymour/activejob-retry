class LoggingJob < ActiveJob::Base
  include ActiveJob::Retry.new(strategy: :constant)

  def perform(dummy)
    logger.info "Dummy, here is it: #{dummy}"
  end

  def job_id
    "LOGGING-JOB-ID"
  end
end

