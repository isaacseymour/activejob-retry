require 'spec_helper'

RSpec.describe ActiveJob::Retry do
  subject(:job) do
    Class.new(ActiveJob::Base) do
      include ActiveJob::Retry

      def perform(*_args)
        raise RuntimeError
      end
    end
  end

  describe '.constant_retry' do
    it 'sets a ConstantBackoffStrategy' do
      job.constant_retry(limit: 10, delay: 5)
      expect(job.backoff_strategy).to be_a(ActiveJob::Retry::ConstantBackoffStrategy)
    end

    context 'invalid options' do
      let(:options) { { limit: -2 } }

      specify do
        expect { job.constant_retry(options) }.
          to raise_error(ActiveJob::Retry::InvalidConfigurationError)
      end
    end
  end

  describe '.variable_retry' do
    it 'sets a VariableBackoffStrategy' do
      job.variable_retry(delays: [0, 5, 10, 60, 200])
      expect(job.backoff_strategy).to be_a(ActiveJob::Retry::VariableBackoffStrategy)
    end

    context 'invalid options' do
      let(:options) { {} }

      specify do
        expect { job.variable_retry(options) }.
          to raise_error(ActiveJob::Retry::InvalidConfigurationError)
      end
    end
  end

  describe '.retry_with' do
    it 'rejects invalid backoff strategies' do
      expect { job.retry_with(Object.new) }.
        to raise_error(ActiveJob::Retry::InvalidConfigurationError)
    end

    it 'sets the backoff_strategy when it is valid' do
      module CustomBackoffStrategy
        def self.should_retry?(_attempt, _exception)
          true
        end

        def self.retry_delay(_attempt, _exception)
          5
        end
      end

      job.retry_with(CustomBackoffStrategy)
      expect(job.backoff_strategy).to eq(CustomBackoffStrategy)
    end
  end

  describe '#serialize' do
    let(:instance) { job.new }
    subject { instance.serialize }

    context 'first instantiated' do
      it { is_expected.to include('retry_attempt' => 1) }
    end

    context '1st attempt' do
      before { instance.instance_variable_set(:@retry_attempt, 1) }
      it { is_expected.to include('retry_attempt' => 1) }
    end

    context '7th attempt' do
      before { instance.instance_variable_set(:@retry_attempt, 7) }
      it { is_expected.to include('retry_attempt' => 7) }
    end
  end

  describe '#deserialize' do
    subject(:instance) { job.new }
    before { instance.deserialize(job_data) }
    before { instance.send(:deserialize_arguments_if_needed) }

    context '1st attempt' do
      let(:job_data) do
        {
          'job_class'     => 'SomeJob',
          'job_id'        => 'uuid',
          'arguments'     => ['arg1', { 'arg' => 2 }],
          'retry_attempt' => 1
        }
      end

      its(:job_id) { is_expected.to eq('uuid') }
      its(:arguments) { is_expected.to eq(['arg1', { 'arg' => 2 }]) }
      its(:retry_attempt) { is_expected.to eq(1) }
    end

    context '7th attempt' do
      let(:job_data) do
        {
          'job_class'     => 'SomeJob',
          'job_id'        => 'uuid',
          'arguments'     => ['arg1', { 'arg' => 2 }],
          'retry_attempt' => 7
        }
      end

      its(:job_id) { is_expected.to eq('uuid') }
      its(:arguments) { is_expected.to eq(['arg1', { 'arg' => 2 }]) }
      its(:retry_attempt) { is_expected.to eq(7) }
    end
  end

  describe '#rescue_with_handler' do
    let(:backoff_strategy) { described_class::ConstantBackoffStrategy.new(limit: 100) }
    let(:instance) { job.new }
    before { job.retry_with(backoff_strategy) }
    subject(:perform) { instance.perform_now }

    context 'when the job should be retried' do
      before do
        expect(backoff_strategy).to receive(:should_retry?).
          with(1, instance_of(RuntimeError)).
          and_return(true)
        expect(backoff_strategy).to receive(:retry_delay).
          with(1, instance_of(RuntimeError)).
          and_return(5)
      end

      it 'retries the job with the defined delay' do
        expect(instance).to receive(:retry_job).with(hash_including(wait: 5))

        perform
      end

      it 'increases the retry_attempt count' do
        perform
        expect(instance.retry_attempt).to eq(2)
      end

      pending 'logs the retry' do
        expect(ActiveJob::Base.logger).to receive(:log).
          with(Logger::INFO, 'Retrying (attempt 1, waiting 0s)')

        perform
      end
    end

    context 'when the job should not be retried' do
      before do
        expect(backoff_strategy).to receive(:should_retry?).
          with(1, instance_of(RuntimeError)).
          and_return(false)
      end

      it 'does not retry the job' do
        expect(instance).to_not receive(:retry_job)

        expect { perform }.to raise_error(RuntimeError)
      end
    end
  end
end
