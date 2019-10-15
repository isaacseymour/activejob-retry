# frozen_string_literal: true

# In Rails 4.2, ActiveJob externally applies deserialized job ID, queue name, arguments to
# the instantiated job in `ActiveJob::Base.deserialize`, which cannot be overridden in
# subclasses. https://github.com/rails/rails/pull/18260 changes this to delegate as much
# of the deserialization as possible to the instance, i.e. `ActiveJob::Base#deserialize`,
# which can be overridden. This allows us to store extra information in the queue (i.e.
# retry_attempt), which is essential for ActiveJob::Retry.
#
# This monkey patch is automatically applied if necessary when ActiveJob::Retry is
# required.

raise 'Unnecessary monkey patch!' if ActiveJob::Base.method_defined?(:deserialize)

module ActiveJob
  class Base
    def self.deserialize(job_data)
      job = job_data['job_class'].constantize.new
      job.deserialize(job_data)
      job
    end

    def deserialize(job_data)
      self.job_id               = job_data['job_id']
      self.queue_name           = job_data['queue_name']
      self.serialized_arguments = job_data['arguments']
    end
  end
end
