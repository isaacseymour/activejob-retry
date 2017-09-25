ActiveJob::Retry [![Build Status](https://travis-ci.org/isaacseymour/activejob-retry.svg?branch=master)](https://travis-ci.org/isaacseymour/activejob-retry)
================

**This is an alpha library** in active development, so the API may change.

Automatic retry functionality for ActiveJob. Just `include ActiveJob::Retry.new(strategy:
:something, **options)` in your job class:

```ruby
class ProcessWebhook < ActiveJob::Base
  queue_as :webhooks

  # Constant delay between attempts:
  include ActiveJob::Retry.new(strategy: :constant,
                               limit: 3,
                               delay: 5.minutes,
                               retryable_exceptions: [TimeoutError, NetworkError])

  # Or, variable delay between attempts:
  include ActiveJob::Retry.new(strategy: :variable,
                               delays: [1.minute, 5.minutes, 10.minutes, 30.minutes])

  # Or, exponential delay between attempts:
  include ActiveJob::Retry.new(strategy: :exponential, limit: 25)

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

  include ActiveJob::Retry.new(strategy: ChaoticBackoffStrategy)

  def perform(webhook)
    webhook.process!
  end
end
```

The retry will get executed **before** any `rescue_from` blocks, which will only get executed
if the exception is not going to be retried, or has failed the final retry.

#### constant options
|  Option                | Default | Description    |
|:---------------------- |:------- |:-------------- |
| `limit`                | `1`     | Maximum number of times to attempt the job (default: 1).
| `unlimited_retries`    | `false` | If set to `true`, this job will be repeated indefinitely until in succeeds. Use with extreme caution.
| `delay`                | `0`     | Time between attempts in seconds (default: 0).
| `retryable_exceptions` | `nil`   | A whitelist of exceptions to retry. When `nil`, all exceptions will result in a retry.
| `fatal_exceptions`     | `[]`    | A blacklist of exceptions to not retry (default: []).

#### exponential options
|  Option                | Default | Description    |
|:---------------------- |:------- |:-------------- |
| `limit`                | `1`     | Maximum number of times to attempt the job (default: 1).
| `unlimited_retries`    | `false` | If set to `true`, this job will be repeated indefinitely until in succeeds. Use with extreme caution.
| `retryable_exceptions` | `nil`   | Same as for [constant](#constant-options).
| `fatal_exceptions`     | `[]`    | Same as for [constant](#constant-options).

#### variable options
| Option                 | Default | Description   |
|:---------------------- |:------- |:------------- |
| `delays`               |         | __required__ An array of delays between attempts in seconds. The first attempt will occur whenever you originally enqueued the job to happen.
| `min_delay_multiplier` |         | If supplied, each delay will be multiplied by a random number between this and `max_delay_multiplier`.
| `max_delay_multiplier` |         | The other end of the range for `min_delay_multiplier`. If one is supplied, both must be.
| `retryable_exceptions` | `nil`   | Same as for [constant](#constant-options).
| `fatal_exceptions`     | `[]`    | Same as for [constant](#constant-options).

## Callback

All strategies support a `callback` option:

```ruby
class ProcessWebhook < ActiveJob::Base
  include ActiveJob::Retry.new(
    strategy: :exponential, limit: 25,
    callback: proc do |exception, delay|
      # will be run before each retry
    end
  )
end
```

`callback` must be a `proc` and is run before each retry. It receives the
exception and delay before the next retry as arguments. It is evaluated on
instance level, so you have access to all instance variables and methods (for
example `retry_attempt`) of your job.

If the callback returns `:halt`, retry chain is halted and no further retries
will be made:

```ruby
class ProcessWebhook < ActiveJob::Base
  include ActiveJob::Retry.new(
    strategy: :exponential, limit: 25,
    callback: proc do |exception, delay|
      if some_condition
        :halt # this will halt the retry chain
      end
    end
  )
end
```

## Supported backends

Any queue adapter which supports delayed enqueuing (i.e. the `enqueue_at`
method) will work with `ActiveJob::Retry`, however some queue backends have
automatic retry logic, which should be disabled. The cleanest way to do this is
to use a `rescue_from` in the jobs for which you're using ActiveJob::Retry, so
the queue backend never perceives the job as having failed. E.g.:

```ruby
class MyJob < ActiveJob::Base
  include ActiveJob::Retry.new(strategy: :constant,
                               limit: 3,
                               delay: 5,
                               retryable_exceptions: [TimeoutError, NetworkError])

  queue_as :some_job

  rescue_from(StandardError) { |error| MyErrorService.record(error) }

  def perform
    raise "Weird!"
  end
end
```

Since `rescue_from`s are only executed once all retries have been attempted,
this will send the recurring error to your error service (e.g. Airbrake,
Sentry), but will make it appear to the queue backend (e.g. Que, Sidekiq) as if
the job has succeeded.

An alternative is to alter the appropriate `JobWrapper` to alter the
configuration of the backend to disable retries globally. For Sidekiq this
would be:

```ruby
# config/initializers/disable_sidekiq_retries.rb
ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper.sidekiq_options(retry: false)
```

This has the advantages of moving failed jobs to the Dead Job Queue instead of
just executing the logic in the `rescue_from`, which makes manual re-enqueueing
easier. On the other hand it does disable Sidekiq's automatic retrying for all
ActiveJob jobs.

Supported Versions
------------------

Rails 4.2, 5.0, and 5.1 are supported, Ruby 2.1+. Other Ruby runtimes (e.g. JRuby,
Rubinius) probably work, but are not tested in Travis CI.

Contributing
------------

Contributions are very welcome! Please open a PR or issue on this repo.
