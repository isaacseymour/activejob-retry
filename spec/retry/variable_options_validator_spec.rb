# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveJob::Retry::VariableOptionsValidator do
  let(:validator) { described_class.new(options) }
  subject(:validate!) { -> { validator.validate! } }

  context 'valid options' do
    context 'empty delays' do
      let(:options) { { delays: [] } }
      it { is_expected.to_not raise_error }
    end

    context 'with delays' do
      let(:options) { { delays: [0, 3, 6, 10_000] } }
      it { is_expected.to_not raise_error }
    end

    context 'min and max delay multipliers' do
      let(:options) do
        { delays: [0, 10, 60], min_delay_multiplier: 0.8, max_delay_multiplier: 1.2 }
      end
      it { is_expected.to_not raise_error }
    end

    context 'fatal exceptions' do
      let(:options) { { delays: [0, 10, 60], fatal_exceptions: [RuntimeError] } }
      it { is_expected.to_not raise_error }
    end

    context 'retryable_exceptions' do
      let(:options) do
        { delays: [], retryable_exceptions: [StandardError, NoMethodError] }
      end
      it { is_expected.to_not raise_error }
    end

    context 'multiple options' do
      let(:options) { { delays: [0, 10, 60], retryable_exceptions: [RuntimeError] } }

      it { is_expected.to_not raise_error }
    end
  end

  context 'invalid options' do
    context 'without delays' do
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
