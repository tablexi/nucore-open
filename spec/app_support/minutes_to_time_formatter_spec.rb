require 'spec_helper'

RSpec.describe MinutesToTimeFormatter do
  let(:action) { described_class.new(minutes) }
  subject(:output) { action.to_s }

  describe 'zero' do
    let(:minutes) { 0 }
    it { should eq('0:00') }
  end

  describe 'less than 10 minutes' do
    let(:minutes) { 7 }
    it { should eq('0:07') }
  end

  describe 'less than an hour' do
    let(:minutes) { 27 }
    it { should eq('0:27') }
  end

  describe 'a single hour' do
    let(:minutes) { 60 }
    it { should eq('1:00') }
  end

  describe 'several hours' do
    let(:minutes) { 201 }
    it { should eq('3:21') }
  end

  describe 'more than 10 hours' do
    let(:minutes) { 601 }
    it { should eq('10:01') }
  end
end
