require 'spec_helper'

RSpec.describe ActiveJob::Retry::VariableBackoffStrategy do
  let(:backoff_strategy) { described_class.new(options) }

  describe '#should_retry?' do
    subject { backoff_strategy.should_retry?(attempt, exception) }
    let(:attempt) { 1 }
    let(:exception) { RuntimeError.new }

    context 'when the strategy is empty' do
      let(:options) { { delays: [] } }

      context '1st attempt' do
        let(:attempt) { 1 }
        it { is_expected.to be(false) }
      end

      context '99999th attempt' do
        let(:attempt) { 99_999 }
        it { is_expected.to be(false) }
      end
    end

    context 'when the strategy has 4 delays' do
      let(:options) { { delays: [0, 3, 5, 10] } }

      context '1st attempt' do
        let(:attempt) { 1 }
        it { is_expected.to be(true) }
      end

      context '4th attempt' do
        let(:attempt) { 4 }
        it { is_expected.to be(true) }
      end

      context '5th attempt' do
        let(:attempt) { 5 }
        it { is_expected.to be(false) }
      end
    end

    context 'defaults (retry everything)' do
      let(:options) { { delays: [0, 3, 5, 10, 60] } }

      context 'Exception' do
        let(:exception) { Exception.new }
        it { is_expected.to be(true) }
      end

      context 'RuntimeError' do
        let(:exception) { RuntimeError.new }
        it { is_expected.to be(true) }
      end

      context 'subclass of RuntimeError' do
        let(:exception) { Class.new(RuntimeError).new }
        it { is_expected.to be(true) }
      end
    end

    context 'with whitelist' do
      let(:options) { { delays: [10], retry_exceptions: [RuntimeError] } }

      context 'Exception' do
        let(:exception) { Exception.new }
        it { is_expected.to be(false) }
      end

      context 'RuntimeError' do
        let(:exception) { RuntimeError.new }
        it { is_expected.to be(true) }
      end

      context 'subclass of RuntimeError' do
        let(:exception) { Class.new(RuntimeError).new }
        it { is_expected.to be(true) }
      end
    end

    context 'with blacklist' do
      let(:options) { { delays: [10], fatal_exceptions: [RuntimeError] } }

      context 'Exception' do
        let(:exception) { Exception.new }
        it { is_expected.to be(true) }
      end

      context 'RuntimeError' do
        let(:exception) { RuntimeError.new }
        it { is_expected.to be(false) }
      end

      context 'subclass of RuntimeError' do
        let(:exception) { Class.new(RuntimeError).new }
        it { is_expected.to be(false) }
      end
    end
  end

  describe '#retry_delay' do
    subject { backoff_strategy.retry_delay(attempt, exception) }
    let(:attempt) { 1 }
    let(:exception) { RuntimeError.new }

    context 'when the strategy has 4 delays' do
      let(:options) { { delays: [0, 3, 5, 10] } }

      context '1st attempt' do
        let(:attempt) { 1 }
        it { is_expected.to eq(0) }
      end

      context '4th attempt' do
        let(:attempt) { 4 }
        it { is_expected.to eq(10) }
      end
    end
  end
end
