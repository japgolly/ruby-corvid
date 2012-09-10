# encoding: utf-8
require_relative '../bootstrap/spec'
require 'corvid/naming_policy'

describe Corvid::NamingPolicy do
  include Corvid::NamingPolicy

  shared_examples 'name validation' do |method|
    it("should pass with valid names"){
      send method, 'a'
      send method, 'corvid'
      send method, 'omg_hehe'
      send method, 'b-123'
    }
    it("should fail when name has whitespace"){
      expect{ send method, 'abc ' }.to raise_error
      expect{ send method, ' abc' }.to raise_error
      expect{ send method, 'a bc' }.to raise_error
      expect{ send method, "a\tbc" }.to raise_error
      expect{ send method, "a\nbc" }.to raise_error
      expect{ send method, "a\rbc" }.to raise_error
    }
    it("should fail when name has a colon"){
      expect{ send method, 'abc:' }.to raise_error
      expect{ send method, ':abc' }.to raise_error
      expect{ send method, 'a:bc' }.to raise_error
    }
    it("should fail when name is empty"){
      expect{ send method, '' }.to raise_error
    }
  end

  describe '#validate_plugin_name!' do
    include_examples 'name validation', :validate_plugin_name!
  end

  describe '#validate_feature_name!' do
    include_examples 'name validation', :validate_feature_name!
  end

  #---------------------------------------------------------------------------------------------------------------------

  shared_examples 'mass name validation' do |method|
    it("should pass with valid names"){
      send method
      send method, []
      send method, 'corvid'
      send method, *%w[a b]
      send method, 'abc', %w[hehe 123], 'ok'
    }
    it("should fail when any name is invalid"){
      expect{ send method, ':' }.to raise_error
      expect{ send method, ':abc', %w[hehe 123], 'ok' }.to raise_error
      expect{ send method, 'abc', %w[:hehe 123], 'ok' }.to raise_error
      expect{ send method, 'abc', %w[hehe :123], 'ok' }.to raise_error
      expect{ send method, 'abc', %w[hehe 123], ':ok' }.to raise_error
    }
  end

  describe '#validate_plugin_names!' do
    include_examples 'mass name validation', :validate_plugin_names!
  end

  describe '#validate_feature_names!' do
    include_examples 'mass name validation', :validate_feature_names!
  end

  #---------------------------------------------------------------------------------------------------------------------

  describe '#validate_feature_id!' do
    it("should pass when id is valid"){
      validate_feature_id! 'abc:123'
      validate_feature_id! 'corvid:corvid'
    }
    it("should fail when id is invalid"){
      expect{ validate_feature_id! ':abc:123' }.to raise_error
      expect{ validate_feature_id! 'abc:123:' }.to raise_error
      expect{ validate_feature_id! 'abc:' }.to raise_error
      expect{ validate_feature_id! ':123' }.to raise_error
      expect{ validate_feature_id! 'abc' }.to raise_error
      expect{ validate_feature_id! '' }.to raise_error
      expect{ validate_feature_id! 'abc:123:hehe' }.to raise_error
      expect{ validate_feature_id! "abc\nhehe" }.to raise_error
      expect{ validate_feature_id! "abc:123\nhehe" }.to raise_error
    }
  end

  describe '#validate_feature_ids!' do
    it("should pass with valid names"){
      validate_feature_ids!
      validate_feature_ids! []
      validate_feature_ids! 'corvid:corvid'
      validate_feature_ids! *%w[a:a b:b]
    }
    it("should fail when any name is invalid"){
      expect{ validate_feature_ids! ':' }.to raise_error
      expect{ validate_feature_ids! 'abchehe', %w[hehe:hehe yes:123], 'y:ok' }.to raise_error
      expect{ validate_feature_ids! 'abc:hehe', %w[hehehehe yes:123], 'y:ok' }.to raise_error
      expect{ validate_feature_ids! 'abc:hehe', %w[hehe:hehe yes123], 'y:ok' }.to raise_error
      expect{ validate_feature_ids! 'abc:hehe', %w[hehe:hehe yes:123], 'yok' }.to raise_error
    }
  end

  #---------------------------------------------------------------------------------------------------------------------

  describe '#feature_id_for' do
    it("should combine names with colon between"){
      feature_id_for('abc','yay').should == 'abc:yay'
    }
  end

  describe '#split_feature_id' do
    it("should split into plugin and feature names"){
      split_feature_id('abc:123').should == %w[abc 123]
    }
    it("should fail feature_id format is invalid"){
      expect{ split_feature_id 'abc' }.to raise_error
      expect{ split_feature_id "ab\nc" }.to raise_error
      expect{ split_feature_id 'abc:123:hehe' }.to raise_error
      expect{ split_feature_id 'abc:123:' }.to raise_error
      expect{ split_feature_id ':abc:123' }.to raise_error
      expect{ split_feature_id 'abc:' }.to raise_error
      expect{ split_feature_id ':abc' }.to raise_error
      expect{ split_feature_id ':abc:' }.to raise_error
      expect{ split_feature_id ':' }.to raise_error
    }
  end
end
