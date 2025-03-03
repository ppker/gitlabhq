# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IgnorableColumns do
  let(:record_class) { Class.new(ApplicationRecord) }

  subject { record_class }

  it 'adds columns to ignored_columns' do
    expect do
      subject.ignore_columns(:name, :created_at, remove_after: '2019-12-01', remove_with: '12.6')
    end.to change { subject.ignored_columns }.from([]).to(%w[name created_at])
  end

  it 'adds columns to ignored_columns (array version)' do
    expect do
      subject.ignore_columns(%i[name created_at], remove_after: '2019-12-01', remove_with: '12.6')
    end.to change { subject.ignored_columns }.from([]).to(%w[name created_at])
  end

  it 'requires remove_after attribute to be set' do
    expect { subject.ignore_columns(:name, remove_after: nil, remove_with: 12.6) }.to raise_error(ArgumentError, /Please indicate/)
  end

  it 'allows setting remove_never: true and not setting other remove options' do
    expect do
      subject.ignore_columns(%i[name created_at], remove_never: true)
    end.to change { subject.ignored_columns }.from([]).to(%w[name created_at])
  end

  it 'requires remove_after attribute to be set' do
    expect { subject.ignore_columns(:name, remove_after: "not a date", remove_with: 12.6) }.to raise_error(ArgumentError, /Please indicate/)
  end

  it 'requires remove_with attribute to be set' do
    expect { subject.ignore_columns(:name, remove_after: '2019-12-01', remove_with: nil) }.to raise_error(ArgumentError, /Please indicate/)
  end

  describe '.ignored_columns_details' do
    shared_examples_for 'storing removal information' do
      it 'storing removal information' do
        subject.ignore_column(columns, remove_after: '2019-12-01', remove_with: '12.6')

        [columns].flatten.each do |column|
          expect(subject.ignored_columns_details[column].remove_after).to eq(Date.parse('2019-12-01'))
          expect(subject.ignored_columns_details[column].remove_with).to eq('12.6')
        end
      end
    end

    context 'with single column' do
      let(:columns) { :name }

      it_behaves_like 'storing removal information'
    end

    context 'with array column' do
      let(:columns) { %i[name created_at] }

      it_behaves_like 'storing removal information'
    end

    context 'when called on a subclass without setting the ignored columns' do
      let(:subclass) { Class.new(record_class) }

      it 'does not raise Deadlock error' do
        expect { subclass.ignored_columns_details }.not_to raise_error
      end
    end

    it 'defaults to empty Hash' do
      expect(subject.ignored_columns_details).to eq({})
    end
  end

  describe IgnorableColumns::ColumnIgnore do
    subject { described_class.new(remove_after, remove_with, remove_never) }

    let(:remove_after) { nil }
    let(:remove_with) { double }
    let(:remove_never) { false }

    describe '#safe_to_remove?' do
      context 'after remove_after date has passed' do
        let(:remove_after) { Date.parse('2019-01-10') }

        it 'returns true (safe to remove)' do
          expect(subject.safe_to_remove?).to be_truthy
        end
      end

      context 'before remove_after date has passed' do
        let(:remove_after) { Date.today }

        it 'returns false (not safe to remove)' do
          expect(subject.safe_to_remove?).to be_falsey
        end
      end

      context 'with remove_never: true' do
        let(:remove_never) { true }

        it 'is false' do
          expect(subject.safe_to_remove?).to be_falsey
        end
      end
    end
  end
end
