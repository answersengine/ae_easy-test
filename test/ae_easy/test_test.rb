require 'test_helper'

describe 'test module' do
  it 'should verbose a message without data' do
    out, err = capture_io do
      AeEasy::Test.verbose_log 'My message, hurray!'
    end
    assert_empty err
    assert_match /^\s*[^:]+:[0-9]+ - My message, hurray!nil\s*$/, out
  end

  it 'should verbose a message with data' do
    out, err = capture_io do
      AeEasy::Test.verbose_log 'My message, hurray! ', 123
    end
    assert_empty err
    assert_match /^\s*[^:]+:[0-9]+ - My message, hurray! 123\s*$/, out
  end

  it 'should verbose a message with data and custom log caller' do
    out, err = capture_io do
      log_caller = [
        'aaa:111:222',
        'bbb:333:444'
      ]
      AeEasy::Test.verbose_log 'My message', 222, log_caller
    end
    assert_empty err
    assert_match /^\s*aaa:111 - My message222\s*$/, out
  end

  it 'should enable/disable test mode' do
    AeEasy::Test.enable_test_mode
    assert AeEasy::Test.test_mode?
    AeEasy::Test.disable_test_mode
    refute AeEasy::Test.test_mode?
    AeEasy::Test.enable_test_mode
    assert AeEasy::Test.test_mode?
  end

  describe 'verbose a match diff' do
    describe 'without caller' do
      it 'with both expected only' do
        diff = {
          expected: [{'aaa' => 'AAA'}, {'bbb' => 'BBB'}],
          saved: [],
          match: false
        }
        out, err = capture_io do
          AeEasy::Test.verbose_match_diff 'my_expected_item', diff
        end
        assert_empty err
        assert_match /\s*[^:]+:[0-9]+ - Non matching expected my_expected_item: \[\{"aaa"=>"AAA"\}, \{"bbb"=>"BBB"\}\]\s*/, out
        refute_match /\s*[^:]+:[0-9]+ - Non matching saved/, out
      end

      it 'with both saved only' do
        diff = {
          expected: [],
          saved: [{'aaa' => 111}, {'bbb' => 222}],
          match: false
        }
        out, err = capture_io do
          AeEasy::Test.verbose_match_diff 'my_saved_item', diff
        end
        assert_empty err
        refute_match /\s*[^:]+:[0-9]+ - Non matching expected/, out
        assert_match /\s*[^:]+:[0-9]+ - Non matching saved my_saved_item: \[\{"aaa"=>111\}, \{"bbb"=>222\}\]\s*/, out
      end

      it 'with both expected and saved' do
        diff = {
          expected: [{'aaa' => 'AAA'}, {'bbb' => 'BBB'}],
          saved: [{'aaa' => 111}, {'bbb' => 222}],
          match: false
        }
        out, err = capture_io do
          AeEasy::Test.verbose_match_diff 'my_item', diff
        end
        assert_empty err
        assert_match /\s*[^:]+:[0-9]+ - Non matching expected my_item: \[\{"aaa"=>"AAA"\}, \{"bbb"=>"BBB"\}\]\s*/, out
        assert_match /\s*[^:]+:[0-9]+ - Non matching saved my_item: \[\{"aaa"=>111\}, \{"bbb"=>222\}\]\s*/, out
      end
    end

    describe 'with caller' do
      before do
        @log_caller = [
          'bbb:333:444',
          'eee:777:888'
        ]
      end

      it 'with both expected only' do
        diff = {
          expected: [{'aaa' => 'AAA'}, {'bbb' => 'BBB'}],
          saved: [],
          match: false
        }
        out, err = capture_io do
          AeEasy::Test.verbose_match_diff 'my_expected_item', diff, @log_caller
        end
        assert_empty err
        assert_match /\s*bbb:333 - Non matching expected my_expected_item: \[\{"aaa"=>"AAA"\}, \{"bbb"=>"BBB"\}\]\s*/, out
        refute_match /\s*[^:]+:[0-9]+ - Non matching saved/, out
      end

      it 'with both saved only' do
        diff = {
          expected: [],
          saved: [{'aaa' => 111}, {'bbb' => 222}],
          match: false
        }
        out, err = capture_io do
          AeEasy::Test.verbose_match_diff 'my_saved_item', diff, @log_caller
        end
        assert_empty err
        refute_match /\s*[^:]+:[0-9]+ - Non matching expected/, out
        assert_match /\s*bbb:333 - Non matching saved my_saved_item: \[\{"aaa"=>111\}, \{"bbb"=>222\}\]\s*/, out
      end

      it 'with both expected and saved' do
        diff = {
          expected: [{'aaa' => 'AAA'}, {'bbb' => 'BBB'}],
          saved: [{'aaa' => 111}, {'bbb' => 222}],
          match: false
        }
        out, err = capture_io do
          AeEasy::Test.verbose_match_diff 'my_item', diff, @log_caller
        end
        assert_empty err
        assert_match /\s*bbb:333 - Non matching expected my_item: \[\{"aaa"=>"AAA"\}, \{"bbb"=>"BBB"\}\]\s*/, out
        assert_match /\s*bbb:333 - Non matching saved my_item: \[\{"aaa"=>111\}, \{"bbb"=>222\}\]\s*/, out
      end
    end
  end
end
