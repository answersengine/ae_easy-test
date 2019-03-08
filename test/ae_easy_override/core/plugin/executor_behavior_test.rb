require 'test_helper'

describe 'executor_behavior' do
  describe 'unit test' do
    before do
      @object = Object.new
      class << @object
        include AeEasy::Core::Plugin::ExecutorBehavior
      end
    end

    it 'should get test_mode' do
      AeEasy::Test.disable_test_mode
      refute AeEasy::Test.test_mode?
      refute @object.test_mode?
      AeEasy::Test.enable_test_mode
      assert AeEasy::Test.test_mode?
      assert @object.test_mode?
      AeEasy::Test.disable_test_mode
      refute AeEasy::Test.test_mode?
      refute @object.test_mode?
    end
  end
end
