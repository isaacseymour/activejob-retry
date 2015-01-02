ActiveJob::Retry [![Build Status](https://travis-ci.org/gocardless/activejob-retry.svg?branch=master)](https://travis-ci.org/gocardless/activejob-retry)
================

**This is an alpha library** in active development, so the API may change.

Automatic retry functionality for ActiveJob. Just `include ActiveJob::Retry` in your job
class and call one of `constant_retry`, `variable_retry`, or `retry_with` to define your
retry strategy:

```ruby
class ProcessWebhook < ActiveJob::Base
  include ActiveJob::Retry

  queue_as :webhooks

  # Constant delay between attempts:
  constant_retry limit: 3, delay: 5, retryable_exceptions: [TimeoutError, NetworkError]

  # Or, variable delay between attempts:
  variable_retry delays: [1, 5, 10, 30]

  # You can also use a custom backoff strategy by passing an object which responds to
  # `should_retry?(attempt, exception)`, and `retry_delay(attempt, exception)`
  # to `retry_with`:
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

#### constant_retry options
|  Option                |  Description          |
|:---------------------- |:--------------------- |
| `limit`                | Maximum number of times to attempt the job (default: 1).
| `unlimited_retries`    | If set to `true`, this job will be repeated indefinitely until in succeeds. Use with extreme caution.
| `delay`                | Time between attempts (default: 0).
| `retryable_exceptions` | A whitelist of exceptions to retry (default: nil, i.e. all exceptions will result in a retry).
| `fatal_exceptions`     | A blacklist of exceptions to not retry (default: []).

#### variable_retry options

| Option                 | Description           |
|:---------------------- |:--------------------- |
| `delays`               |  __required__ An array of delays between attempts. The first attempt will occur whenever you originally enqueued the job to happen.
| `min_delay_multiplier` | If supplied, each delay will be multiplied by a random number between this and `max_delay_multiplier`.
| `max_delay_multiplier` | The other end of the range for `min_delay_multiplier`. If one is supplied, both must be.
| `retryable_exceptions` | Same as for `constant_retry`.
| `fatal_exceptions`     |Same as for `constant_retry`.

Contributing
------------

Contributions are very welcome! Please open a PR or issue on this repo.
