require 'spec_helper'

RSpec.describe ActiveJob::Retry::VariableOptionsValidator do
  let(:validator) { described_class.new(options) }
  subject(:validate!) { -> { validator.validate! } }

  context 'valid options' do
    context 'empty strategy' do
      let(:options) { { strategy: [] } }
      it { is_expected.to_not raise_error }
    end

    context 'with strategy' do
      let(:options) { { strategy: [0, 3, 6, 10_000] } }
      it { is_expected.to_not raise_error }
    end

    context 'min and max delay multipliers' do
      let(:options) do
        { strategy: [0, 10, 60], min_delay_multiplier: 0.8, max_delay_multiplier: 1.2 }
      end
      it { is_expected.to_not raise_error }
    end

    context 'fatal exceptions' do
      let(:options) { { strategy: [0, 10, 60], fatal_exceptions: [RuntimeError] } }
      it { is_expected.to_not raise_error }
    end

    context 'retry exceptions' do
      let(:options) { { strategy: [], retry_exceptions: [StandardError, NoMethodError] } }
      it { is_expected.to_not raise_error }
    end

    context 'multiple options' do
      let(:options) { { strategy: [0, 10, 60], retry_exceptions: [RuntimeError] } }

      it { is_expected.to_not raise_error }
    end
  end

  context 'invalid options' do
    context 'without a strategy' do
      let(:options) { {} }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end

    context 'with limit' do
      let(:options) { { limit: 5 } }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end

    context 'with delay' do
      let(:options) { { delay: 5 } }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end

    context 'min delay multiplier only' do
      let(:options) { { min_delay_multiplier: 0.8 } }
      it { is_expected.to raise_error(ActiveJob::Retry::InvalidConfigurationError) }
    end

    context 'max delay multiplier only' do
      let(:options) { { max_delay_multiplier: 0.8 } }
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
