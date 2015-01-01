require File.expand_path('../lib/active_job/retry/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'activejob-retry'
  s.version = ActiveJob::Retry::VERSION
  s.date = Date.today.strftime('%Y-%m-%d')
  s.authors = ['Isaac Seymour']
  s.email = ['isaac@isaacseymour.co.uk']
  s.summary = 'Automatic retry functionality for ActiveJob.'
  s.description = <<-EOL
    activejob-retry provides automatic retry functionality for failed
    ActiveJobs, with exponential backoff.

    Features:

    * Works with any queue adapter that supports retries.
    * Whitelist/blacklist exceptions to retry on.
    * Exponential backoff (varying the delay between retries).
    * Light and easy to override retry logic.
  EOL
  s.homepage = 'http://github.com/gocardless/activejob-retry'
  s.license = 'MIT'

  s.has_rdoc = false
  s.files = `git ls-files`.split($/)
  s.require_paths = %w[lib]

  s.add_dependency('activejob', '>= 4.2')
  s.add_dependency('activesupport', '>= 4.2')

  s.add_development_dependency('rake', ' >= 10.3')
  s.add_development_dependency('rspec')
  s.add_development_dependency('rspec-its')
end
