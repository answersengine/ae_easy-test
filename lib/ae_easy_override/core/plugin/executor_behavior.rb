module AeEasy
  module Core
    module Plugin
      module ExecutorBehavior
        def test_mode?
          AeEasy::Test.test_mode?
        end
      end
    end
  end
end
