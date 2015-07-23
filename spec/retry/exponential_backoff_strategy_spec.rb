require 'spec_helper'

RSpec.describe ActiveJob::Retry::ExponentialBackoffStrategy do
  let(:strategy) { described_class.new(options) }

  describe '#should_retry?' do
    subject { strategy.should_retry?(attempt, exception) }
    let(:attempt) { 1 }
    let(:exception) { RuntimeError.new }

    context 'when the limit is infinite' do
      let(:options) { { limit: nil, unlimited_retries: true } }

      context '1st attempt' do
        let(:attempt) { 1 }
        it { is_expected.to be(true) }
      end

      context '99999th attempt' do
        let(:attempt) { 99_999 }
        it { is_expected.to be(true) }
      end
    end

    context 'when the limit is 0' do
      let(:options) { { limit: 0 } }

      context '1st attempt' do
        let(:attempt) { 1 }
        it { is_expected.to be(false) }
      end

      context '99999th attempt' do
        let(:attempt) { 99_999 }
        it { is_expected.to be(false) }
      end
    end

    context 'when the limit is 5' do
      let(:options) { { limit: 5 } }

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
      let(:options) { { limit: 10 } }

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
      let(:options) { { limit: 10, retryable_exceptions: [RuntimeError] } }

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
      let(:options) { { limit: 10, fatal_exceptions: [RuntimeError] } }

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
    subject { strategy.retry_delay(attempt, exception) }
    let(:exception) { RuntimeError.new }

    context 'limited retries' do
      let(:options) { { limit: 5 } }
      let(:attempt) { 1 }

      let(:attempt_3_delay) { strategy.retry_delay(attempt_3, exception) }
      let(:attempt_5_delay) { strategy.retry_delay(attempt_5, exception) }

      let(:attempt_3) { 3 }
      let(:attempt_5) { 5 }

      it 'returns value greater than previous for each of the following attempts' do
        expect(subject).to be < attempt_3_delay
        expect(attempt_3_delay).to be < attempt_5_delay
      end
    end

    context 'unlimited retries' do
      let(:options) { { limit: nil, unlimited_retries: true } }
      let(:attempt) { 1000 }

      specify { expect { subject }.to_not raise_error }
    end
  end
end
