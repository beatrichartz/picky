# coding: utf-8
#
require 'spec_helper'

describe Picky::Query::Combinations do

  before(:each) do
    @combinations_ary = stub :combinations_ary
    
    @combinations = described_class.new @combinations_ary
  end
  
  describe "to_result" do
    before(:each) do
      @combination1 = stub :combination1, :to_result => :result1
      @combination2 = stub :combination2, :to_result => :result2
      
      @combinations_ary = [@combination1, @combination2]
      
      @combinations = described_class.new @combinations_ary
    end
    it "resultifies the combinations" do
      @combinations.to_result.should == [:result1, :result2]
    end
  end
  
  describe "weighted_score" do
    it "uses the weights' score method" do
      weights = stub :weights
      weights.should_receive(:score_for).once.with @combinations_ary
      
      @combinations.weighted_score weights
    end
  end
  
  describe "total_score" do
    before(:each) do
      @combination1 = stub :combination1, :weight => 3.14
      @combination2 = stub :combination2, :weight => 2.76
      
      @combinations_ary = [@combination1, @combination2]
      
      @combinations = described_class.new @combinations_ary
    end
    it "sums the scores" do
      @combinations.total_score.should == 5.90
    end
  end
  
  describe "calculate_score" do
    before(:each) do
      @combinations.stub! :total_score => 0
      @combinations.stub! :weighted_score => 0
    end
    it "first sums, then weighs" do
      @combinations.should_receive(:total_score).once.ordered.and_return 0
      @combinations.should_receive(:weighted_score).once.ordered.and_return 0
      
      @combinations.calculate_score :anything
    end
    it "calls sum_score" do
      @combinations.should_receive(:total_score).once.with.and_return 0
      
      @combinations.calculate_score :anything
    end
    it "calls sum_score" do
      @combinations.should_receive(:weighted_score).once.with(:weights).and_return 0
      
      @combinations.calculate_score :weights
    end
  end
  
  describe 'hash' do
    it "delegates to the combinations array" do
      @combinations_ary.should_receive(:hash).once.with
      
      @combinations.hash
    end
  end
  
  describe 'remove' do
    before(:each) do
      @combination1 = stub :combination1, :category => :other
      @combination2 = stub :combination2, :category => :to_remove
      @combination3 = stub :combination3, :category => :to_remove

      @combinations = described_class.new [@combination1, @combination2, @combination3]
    end
    it 'should remove the combinations' do
      @combinations.remove([:to_remove]).should == [@combination1]
    end
  end

end