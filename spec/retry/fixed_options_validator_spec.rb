require 'spec_helper'

RSpec.describe ActiveJob::Retry::FixedOptionsValidator do
  let(:validator) { described_class.new(options) }
  subject(:validate!) { -> { validator.validate! } }

  context 'valid options' do
    context 'infinite retries' do
      let(:options) { { limit: -1, infinite_job: true } }
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

    context 'zero delay' do
      let(:options) { { delay: 0 } }
      it { is_expected.to_not raise_error }
    end

    context 'fatal exceptions' do
      let(:options) { { fatal_exceptions: [RuntimeError] } }
      it { is_expected.to_not raise_error }
    end

    context 'retry exceptions' do
      let(:options) { { retry_exceptions: [StandardError, NoMethodError] } }
      it { is_expected.to_not raise_error }
    end

    context 'multiple options' do
      let(:options) { { limit: 3, delay: 10, retry_exceptions: [RuntimeError] } }

      it { is_expected.to_not raise_error }
    end
  end

  context 'invalid options' do
    context 'bad limit' do
      let(:options) { { limit: -2 } }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end

    context 'accidental infinite limit' do
      let(:options) { { limit: -1 } }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end

    context 'bad delay' do
      let(:options) { { delay: -1 } }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end

    context 'bad fatal exceptions' do
      let(:options) { { fatal_exceptions: ['StandardError'] } }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end

    context 'bad retry exceptions' do
      let(:options) { { retry_exceptions: [:runtime] } }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end

    context 'retry and fatal exceptions together' do
      let(:options) { { fatal_exceptions: [StandardError], retry_exceptions: [] } }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end
  end
end
