require 'spec_helper'

RSpec.describe ActiveJob::Retry::FixedDelayRetrier do
  let(:retrier) { described_class.new(options) }

  describe '#should_retry?' do
    subject { retrier.should_retry?(attempt, exception) }
    let(:attempt) { 1 }
    let(:exception) { RuntimeError.new }

    context 'when the limit is infinite' do
      let(:options) { { limit: -1, infinite_job: true } }

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
      let(:options) { { limit: 10, retry_exceptions: [RuntimeError] } }

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
end
