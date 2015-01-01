ActiveJob::Retry [![Build Status](https://travis-ci.org/gocardless/activejob-retry.svg?branch=master)](https://travis-ci.org/gocardless/activejob-retry)
================

Automatic retry functionality for ActiveJob. Just `include ActiveJob::Retry` in your job
class and call one of `constant_retry`, `variable_retry`, or `retry_with` to define your
retry strategy:

```ruby
class ProcessWebhook < ActiveJob::Base
  include ActiveJob::Retry

  queue_as :webhooks

  # Constant delay between attempts
  constant_retry limit: 3,                          # Attempt three times and then raise (default: 1)
                 delay: 5,                          # Wait ~5 seconds between attempts (default: 0)
                 retry_exceptions: [TimeoutError]   # Only retry when these errors are raised (default: all)
                 # Could alternatively use:
                 # fatal_exceptions: [StandardError] # Never catch these errors (default: none)

  # Variable delay between attempts
  variable_retry delays: [1, 5, 10, 30, 60] # Delay for 1, 5, ... seconds between subsequent retries (note that n delays means n+1 attempts)
                 min_delay_multiplier: 0.8, # Multiply each delay by a random number between
                 max_delay_multiplier: 1.2  # 0.8 and 1.2 (rounded to nearest second)

  # These use ConstantBackoffStrategy and VariableBackoffStrategy, but you can use a custom
  # backoff strategy by passing an object which responds to `should_retry?(retry_attempt, exception)`,
  # and `retry_delay(retry_attempt, exception)` to `retry_with`:
  module ChaoticBackoffStrategy
    def self.should_retry?(retry_attempt, exception)
      [true, true, true, true, false].sample
    end

    def self.retry_delay(retry_attempt, exception)
      (0..10).to_a.sample
    end
  end

  retry_with ChaoticBackoffStrategy

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
