ActiveJob::Retry
================

A DSL for automatically retrying ActiveJobs, with exponential backoff.

```ruby
class ProcessWebhook < ActiveJob::Base
  include ActiveJob::Retry

  queue_as :webhooks
  retry_with limit: 3,                          # Attempt three times and then raise (default: 1)
             delay: 5,                          # Wait ~5 seconds between attempts (default: 0)
             retry_exceptions: [TimeoutError]   # Only retry when these errors are raised (default: all)
             # Could alternatively use:
             # fatal_exceptions: [StandardError] # Never catch these errors (default: none)

  def process(webhook)
    webhook.process!
  end
end
```

Contributing
------------

  * Fork the project.
  * Make your feature addition or bug fix.
  * Add tests for it.
  * Document it in the CHANGELOG.md.
  * Open a PR.
