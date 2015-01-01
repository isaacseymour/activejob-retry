require 'spec_helper'

RSpec.describe ActiveJob::Retry do
  subject(:job) { Class.new(ActiveJob::Base) { include ActiveJob::Retry } }

  describe '.retry_with' do
    context 'valid options' do
      before { job.retry_with(options) }

      context 'limit only' do
        context 'infinite retries' do
          let(:options) { { limit: -1, infinite_job: true } }
          its(:retry_limit) { is_expected.to eq(-1) }
        end

        context 'no retries' do
          let(:options) { { limit: 0 } }
          its(:retry_limit) { is_expected.to eq(0) }
        end

        context 'some retries' do
          let(:options) { { limit: 3 } }
          its(:retry_limit) { is_expected.to eq(3) }
        end
      end

      context 'delay only' do
        let(:options) { { delay: 0 } }
        its(:retry_delay) { is_expected.to eq(0) }
      end

      context 'fatal exceptions' do
        let(:options) { { fatal_exceptions: [RuntimeError] } }
        its(:fatal_exceptions) { is_expected.to eq([RuntimeError]) }
      end

      context 'retry exceptions' do
        let(:options) { { retry_exceptions: [StandardError, NoMethodError] } }
        its(:retry_exceptions) { is_expected.to eq([StandardError, NoMethodError]) }
      end

      context 'multiple options' do
        let(:options) { { limit: 3, delay: 10, retry_exceptions: [RuntimeError] } }

        its(:retry_limit) { is_expected.to eq(3) }
        its(:retry_delay) { is_expected.to eq(10) }
        its(:retry_exceptions) { is_expected.to eq([RuntimeError]) }
      end
    end

    context 'invalid options' do
      subject { -> { job.retry_with(options) } }

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

  describe '.retry_exception?' do
    subject { job.retry_exception?(exception) }

    context 'defaults (retry everything)' do
      context 'Exception' do
        let(:exception) { Exception.new }
        it { is_expected.to be_truthy }
      end

      context 'RuntimeError' do
        let(:exception) { RuntimeError.new }
        it { is_expected.to be_truthy }
      end

      context 'InvalidConfigurationError' do
        let(:exception) { ActiveJob::Retry::InvalidConfigurationError.new }
        it { is_expected.to be_truthy }
      end
    end

    context 'with whitelist' do
      before { job.retry_with(retry_exceptions: [RuntimeError]) }

      context 'Exception' do
        let(:exception) { Exception.new }
        it { is_expected.to be_falsey }
      end

      context 'RuntimeError' do
        let(:exception) { RuntimeError.new }
        it { is_expected.to be_truthy }
      end

      context 'subclass of RuntimeError' do
        let(:exception) { Class.new(RuntimeError).new }
        it { is_expected.to be_truthy }
      end
    end

    context 'with blacklist' do
      before { job.retry_with(fatal_exceptions: [RuntimeError]) }

      context 'Exception' do
        let(:exception) { Exception.new }
        it { is_expected.to be_truthy }
      end

      context 'RuntimeError' do
        let(:exception) { RuntimeError.new }
        it { is_expected.to be_falsey }
      end

      context 'subclass of RuntimeError' do
        let(:exception) { Class.new(RuntimeError).new }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#retry_limit_reached?' do
    let(:instance) { job.tap { |job| job.retry_with(options) }.new }
    subject { instance.retry_limit_reached? }

    context 'when the limit is infinite' do
      let(:options) { { limit: -1, infinite_job: true } }

      context 'first attempt' do
        before { instance.instance_variable_set(:@retry_attempt, 1) }
        it { is_expected.to be_falsey }
      end

      context '99999th attempt' do
        before { instance.instance_variable_set(:@retry_attempt, 99999) }
        it { is_expected.to be_falsey }
      end
    end

    context 'when the limit is 0' do
      let(:options) { { limit: 0 } }

      context 'first attempt' do
        before { instance.instance_variable_set(:@retry_attempt, 1) }
        it { is_expected.to be_truthy }
      end

      context '99999th attempt' do
        before { instance.instance_variable_set(:@retry_attempt, 99999) }
        it { is_expected.to be_truthy }
      end
    end

    context 'when the limit is 5' do
      let(:options) { { limit: 5 } }

      context 'first attempt' do
        before { instance.instance_variable_set(:@retry_attempt, 1) }
        it { is_expected.to be_falsey }
      end

      context '4th attempt' do
        before { instance.instance_variable_set(:@retry_attempt, 4) }
        it { is_expected.to be_falsey }
      end

      context '5th attempt' do
        before { instance.instance_variable_set(:@retry_attempt, 5) }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#retry_or_reraise' do
    let(:instance) { job.new }
    let(:exception) { RuntimeError.new }
    subject(:retry_or_reraise) { instance.retry_or_reraise(exception) }

    context 'when we should not retry' do
      before do
        allow(instance).to receive(:should_retry?).with(exception).and_return(false)
      end

      specify { expect { retry_or_reraise }.to raise_error(exception) }
    end

    context 'when we should retry' do
      before do
        allow(instance).to receive(:should_retry?).with(exception).and_return(true)
        allow(instance).to receive(:retry_job).and_return(true)
      end

      pending 'logs the retry' do
        expect(ActiveJob::Base.logger).to receive(:log).
          with(Logger::INFO, 'Retrying (attempt 1, waiting 0s)')
        retry_or_reraise
      end

      it 'retries the job' do
        expect(instance).to receive(:retry_job).with(wait: 0)
        retry_or_reraise
      end
    end
  end
end
