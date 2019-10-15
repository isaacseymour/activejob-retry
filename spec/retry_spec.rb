# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveJob::Retry do
  let(:strategy) { :constant }
  let(:options) { {} }
  let(:retry_instance) { described_class.new(strategy: strategy, **options) }
  let(:job) do
    Class.new(ActiveJob::Base) do
      def perform(*_args)
        raise RuntimeError
      end
    end.send(:include, retry_instance)
  end

  describe 'constant strategy' do
    let(:strategy) { :constant }
    let(:options) { { limit: 10, delay: 5 } }

    it 'sets a ConstantBackoffStrategy' do
      expect(job.backoff_strategy).to be_a(ActiveJob::Retry::ConstantBackoffStrategy)
    end

    context 'invalid options' do
      let(:options) { { limit: -2 } }

      specify do
        expect { retry_instance }.
          to raise_error(ActiveJob::Retry::InvalidConfigurationError)
      end
    end

    context 'subclassing' do
      let(:subclass) { Class.new(job) }
      it 'has the ConstantBackoffStrategy' do
        expect(subclass.backoff_strategy).
          to be_a(ActiveJob::Retry::ConstantBackoffStrategy)
      end
    end
  end

  describe 'variable strategy' do
    let(:strategy) { :variable }
    let(:options) { { delays: [0, 5, 10, 60, 200] } }

    it 'sets a VariableBackoffStrategy' do
      expect(job.backoff_strategy).to be_a(ActiveJob::Retry::VariableBackoffStrategy)
    end

    context 'invalid options' do
      let(:options) { {} }

      specify do
        expect { retry_instance }.
          to raise_error(ActiveJob::Retry::InvalidConfigurationError)
      end
    end

    context 'subclassing' do
      let(:subclass) { Class.new(job) }
      it 'has the VariableBackoffStrategy' do
        expect(subclass.backoff_strategy).
          to be_a(ActiveJob::Retry::VariableBackoffStrategy)
      end

      it 'allows overriding' do
        subclass.send(:include, described_class.new(strategy: :constant))
        expect(subclass.backoff_strategy).
          to be_a(ActiveJob::Retry::ConstantBackoffStrategy)
      end
    end
  end

  describe 'exponential strategy' do
    let(:strategy) { :exponential }
    let(:options) { { limit: 10 } }

    it 'sets an ExponentialBackoffStrategy' do
      expect(job.backoff_strategy).to be_a(ActiveJob::Retry::ExponentialBackoffStrategy)
    end

    context 'invalid limit' do
      let(:options) { { limit: -2 } }

      specify do
        expect { retry_instance }.
          to raise_error(ActiveJob::Retry::InvalidConfigurationError)
      end
    end

    context 'invalid option included' do
      let(:options) { { limit: 2, delay: 3 } }

      specify do
        expect { retry_instance }.
          to raise_error(ActiveJob::Retry::InvalidConfigurationError)
      end
    end

    context 'subclassing' do
      let(:subclass) { Class.new(job) }
      it 'has the ExponentialBackoffStrategy' do
        expect(subclass.backoff_strategy).
          to be_a(ActiveJob::Retry::ExponentialBackoffStrategy)
      end
    end
  end

  describe 'custom strategy' do
    module CustomBackoffStrategy
      def self.should_retry?(_attempt, _exception)
        true
      end

      def self.retry_delay(_attempt, _exception)
        5
      end
    end

    it 'rejects invalid backoff strategies' do
      expect { described_class.new(strategy: Object.new) }.
        to raise_error(ActiveJob::Retry::InvalidConfigurationError)
    end

    let(:strategy) { CustomBackoffStrategy }

    it 'sets the backoff_strategy when it is valid' do
      expect(job.backoff_strategy).to eq(CustomBackoffStrategy)
    end

    context 'subclassing' do
      let(:subclass) { Class.new(job) }
      it 'has the CustomBackoffStrategy' do
        expect(subclass.backoff_strategy).to eq(strategy)
      end
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

    context 'when inherited' do
      let(:subclass) { Class.new(job) }
      let(:instance) { subclass.new }
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
  end

  describe '#deserialize' do
    subject(:instance) { job.new }
    before { instance.deserialize(job_data) }
    before { instance.send(:deserialize_arguments_if_needed) }

    context '1st attempt' do
      let(:job_data) do
        {
          'job_class' => 'SomeJob',
          'job_id' => 'uuid',
          'arguments' => ['arg1', { 'arg' => 2 }],
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
          'job_class' => 'SomeJob',
          'job_id' => 'uuid',
          'arguments' => ['arg1', { 'arg' => 2 }],
          'retry_attempt' => 7
        }
      end

      its(:job_id) { is_expected.to eq('uuid') }
      its(:arguments) { is_expected.to eq(['arg1', { 'arg' => 2 }]) }
      its(:retry_attempt) { is_expected.to eq(7) }
    end

    context 'when subclassing' do
      let(:subclass) { Class.new(job) }
      subject(:instance) { subclass.new }
      before { instance.deserialize(job_data) }
      before { instance.send(:deserialize_arguments_if_needed) }

      context '1st attempt' do
        let(:job_data) do
          {
            'job_class' => 'SomeJob',
            'job_id' => 'uuid',
            'arguments' => ['arg1', { 'arg' => 2 }],
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
            'job_class' => 'SomeJob',
            'job_id' => 'uuid',
            'arguments' => ['arg1', { 'arg' => 2 }],
            'retry_attempt' => 7
          }
        end

        its(:job_id) { is_expected.to eq('uuid') }
        its(:arguments) { is_expected.to eq(['arg1', { 'arg' => 2 }]) }
        its(:retry_attempt) { is_expected.to eq(7) }
      end
    end
  end

  describe '#rescue_with_handler' do
    let(:mod) { described_class.new(strategy: :constant, limit: 100) }
    let(:instance) { job.new }
    subject(:perform) { instance.perform_now }

    context 'when the job should be retried' do
      before do
        expect(job.backoff_strategy).to receive(:should_retry?).
          with(1, instance_of(RuntimeError)).
          and_return(true)
        expect(job.backoff_strategy).to receive(:retry_delay).
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
        expect(job.backoff_strategy).to receive(:should_retry?).
          with(1, instance_of(RuntimeError)).
          and_return(false)
      end

      it 'does not retry the job' do
        expect(instance).to_not receive(:retry_job)

        expect { perform }.to raise_error(RuntimeError)
      end
    end
  end

  describe 'retry callback' do
    let(:retry_instance) do
      described_class.new(strategy: :constant, callback: callback, **options)
    end
    let(:callback_double) { double(call: nil) }
    let(:callback) { callback_double.method(:call).to_proc }
    let(:instance) { job.new }
    subject(:perform) { instance.perform_now }

    context 'invalid options' do
      let(:callback) { 'not a proc' }

      specify do
        expect { retry_instance }.
          to raise_error(ActiveJob::Retry::InvalidConfigurationError)
      end
    end

    context 'when the job should be retried' do
      before do
        expect(job.backoff_strategy).to receive(:should_retry?).
          with(1, instance_of(RuntimeError)).
          and_return(true)
      end

      it 'executes callback proc on retry' do
        expect(callback_double).to receive(:call)
        perform
      end

      context 'with callback returning :halt' do
        let(:callback) { proc { :halt } }

        it 'it does not retry the job' do
          expect(instance).not_to receive(:retry_job)

          perform
        end
      end

      context 'with callback not returning :halt' do
        let(:callback) { proc { 'not halt' } }

        it 'it retries the job' do
          expect(instance).to receive(:retry_job)

          perform
        end
      end
    end
  end
end
