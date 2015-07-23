require 'spec_helper'

RSpec.describe ActiveJob::Retry::ExponentialOptionsValidator do
  let(:validator) { described_class.new(options) }
  subject(:validate!) { -> { validator.validate! } }

  context 'valid options' do
    context 'unlimited retries' do
      let(:options) { { limit: nil, unlimited_retries: true } }
      it { is_expected.to_not raise_error }
    end

    context 'no retries' do
      let(:options) { { limit: 0 } }
      it { is_expected.to_not raise_error }
    end

    context 'some retries' do
      let(:options) { { limit: 3 } }
      it { is_expected.to_not raise_error }
    end

    context 'fatal_exceptions' do
      let(:options) { { fatal_exceptions: [RuntimeError] } }
      it { is_expected.to_not raise_error }
    end

    context 'retryable_exceptions' do
      let(:options) { { retryable_exceptions: [StandardError, NoMethodError] } }
      it { is_expected.to_not raise_error }
    end

    context 'multiple options' do
      let(:options) { { limit: 3, retryable_exceptions: [RuntimeError] } }

      it { is_expected.to_not raise_error }
    end
  end

  context 'invalid options' do
    context 'bad limit' do
      let(:options) { { limit: -1 } }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end

    context 'accidental infinite limit' do
      let(:options) { { limit: nil } }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end

    context 'accidental finite limit' do
      let(:options) { { unlimited_retries: true } }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end

    context 'delay provided' do
      let(:options) { { delay: 1 } }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end

    context 'bad fatal_exceptions' do
      let(:options) { { fatal_exceptions: ['StandardError'] } }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end

    context 'bad retryable_exceptions' do
      let(:options) { { retryable_exceptions: [:runtime] } }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end

    context 'retry and fatal exceptions together' do
      let(:options) { { fatal_exceptions: [StandardError], retryable_exceptions: [] } }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end
  end
end
