# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_job/retry/version'

Gem::Specification.new do |s|
  s.name = 'activejob-retry'
  s.version = ActiveJob::Retry::VERSION
  s.date = Date.today.strftime('%Y-%m-%d')
  s.authors = ['Isaac Seymour']
  s.email = ['isaac@isaacseymour.co.uk']
  s.summary = 'Automatically retry ActiveJobs, with exponential backoff.'
  s.description = <<-EOL
    activejob-retry provides automatic retry functionality for failed
    ActiveJobs, with exponential backoff.

    Features:

    * Works with any queue adapter that supports retries.
    * Whitelist/blacklist exceptions to retry on.
    * Exponential backoff (varying the delay between retries).
    * Light and easy to override retry logic.
  EOL
  s.homepage = 'http://github.com/isaacseymour/activejob-retry'
  s.license = 'MIT'

  s.has_rdoc = false
  s.files = `git ls-files`.split($/)
  s.require_paths = %w[lib]

  s.add_dependency('activejob', '>= 4.2')

  s.add_development_dependency('rspec')
  s.add_development_dependency('rspec-its')
  s.add_development_dependency('pry-byebug')
end
