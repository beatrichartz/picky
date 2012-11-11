# encoding: utf-8
#
require 'spec_helper'

describe "automatic splitting" do

  it 'can split text automatically' do
    index = Picky::Index.new :automatic_text_splitting do
      indexing removes_characters: /[^a-z\s]/i,
               stopwords: /\b(in|a)\b/
      category :text
    end

    require 'ostruct'
    index.add OpenStruct.new(id: 1, text: 'It does rain in Spain. Purple is a new color. Bow to the king.')
    index.add OpenStruct.new(id: 2, text: 'Rainbow rainbow.')
    index.add OpenStruct.new(id: 3, text: 'Bow and arrow in Papua New Guinea.')
    index.add OpenStruct.new(id: 4, text: 'The color purple.')
    index.add OpenStruct.new(id: 5, text: 'Sun and rain.')
    index.add OpenStruct.new(id: 6, text: 'The king is in Spain.')
    
    automatic_splitter = Picky::Splitters::Automatic.new index[:text]
    
    # It splits the text correctly.
    #
    automatic_splitter.split('purplerainbow').should == ['purple', 'rain', 'bow']
    automatic_splitter.split('purplerain').should == ['purple', 'rain']
    automatic_splitter.split('purple').should == ['purple']
    
    # When it can't, it splits it using the partial index (correctly).
    #
    automatic_splitter.split('purplerainbo').should == ['purple', 'rain', 'bo']
    automatic_splitter.split('purplerainb').should == ['purple', 'rain', 'b']
    #
    automatic_splitter.split('purplerai').should == ['purple', 'rai']
    automatic_splitter.split('purplera').should == ['purple', 'ra']
    automatic_splitter.split('purpler').should == ['purple', 'r']
    #
    automatic_splitter.split('purpl').should == ['purpl']
    automatic_splitter.split('purp').should == ['purp']
    automatic_splitter.split('pur').should == ['pur']
    automatic_splitter.split('pu').should == ['pu']
    automatic_splitter.split('p').should == ['p']
    
    try = Picky::Search.new index do
      searching splits_text_on: automatic_splitter
    end
    
    # Should find the one with all parts.
    #
    try.search('purplerainbow').ids.should == [1]
    try.search('sunandrain').ids.should == [5]
    
    # Common parts are found in multiple examples.
    #
    try.search('colorpurple').ids.should == [4,1]
    try.search('bownew').ids.should      == [3,1]
    try.search('spainisking').ids.should == [6,1]
  end

end