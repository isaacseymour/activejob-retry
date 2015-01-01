ActiveJob::Retry
================

Automatic retry functionality for ActiveJob.

```ruby
class ProcessWebhook < ActiveJob::Base
  include ActiveJob::Retry

  queue_as :webhooks
  retry_with limit: 3,                          # Attempt three times and then raise (default: 1)
             delay: 5,                          # Wait ~5 seconds between attempts (default: 0)
             retry_exceptions: [TimeoutError]   # Only retry when these errors are raised (default: all)
             # Could alternatively use:
             # fatal_exceptions: [StandardError] # Never catch these errors (default: none)

  def perform(webhook)
    webhook.process!
  end
end
```

With exponential backoff:

```ruby
class ProcessWebhook < ActiveJob::Base
  include ActiveJob::Retry::ExponentialBackoff

  queue_as :webhooks
  backoff_with strategy: [1, 5, 10, 30, 60] # Delay for 1, 5, ... seconds between subsequent retries
               min_delay_multiplier: 0.8,   # Multiply each delay by a random number between
               max_delay_multiplier: 1.2    # 0.8 and 1.2 (rounded to nearest second)

  def perform(webhook)
    webhook.process!
  end
end
```

Contributing
------------

  * Fork the project.
  * Make your feature addition or bug fix.
  * Add tests for it.
  * Open a PR.
