require 'test_helper'

describe 'test helper module' do
  before do
    Dir.mkdir('./tmp') unless Dir.exist?('./tmp')
    Dir.mkdir('./tmp/helper') unless Dir.exist?('./tmp/helper')
    @temp_dir = './tmp/helper'
  end

  describe 'unit test' do
    describe 'non json file' do
      it 'should load when exists' do
        Dir.mktmpdir(nil, @temp_dir) do |dir|
          file = nil
          begin
            expected = "
              Hello, this is file
              Yes file, this is text
            ".freeze
            file = Tempfile.new(['content'], dir, encoding: 'UTF-8')
            file.write expected
            file.close
            data = AeEasy::Test::Helper.load_file file.path
            assert_equal expected, data
          ensure
            file.unlink unless file.nil?
          end
        end
      end

      it 'should get empty when empty file' do
        Dir.mktmpdir(nil, @temp_dir) do |dir|
          file = nil
          begin
            expected = "".freeze
            file = Tempfile.new(['content'], dir, encoding: 'UTF-8')
            file.close
            data = AeEasy::Test::Helper.load_file file.path
            assert_equal expected, data
          ensure
            file.unlink unless file.nil?
          end
        end
      end

      it 'should get nil when not exists' do
        data = AeEasy::Test::Helper.load_file "./test/aaaaaa"
        assert_nil data
      end
    end

    describe 'json file' do
      it 'should load when exists' do
        Dir.mktmpdir(nil, @temp_dir) do |dir|
          file = nil
          begin
            expected = [
              {'aaa' => 111},
              {'bbb' => 'BBB'}
            ]
            file = Tempfile.new(['test', 'json'], dir, encoding: 'UTF-8')
            file.write '[
              {"aaa": 111},
              {"bbb": "BBB"}
            ]'
            file.close
            data = AeEasy::Test::Helper.load_json_file file.path
            assert_equal expected, data
          ensure
            file.unlink unless file.nil?
          end
        end
      end

      it 'should get nil when empty file' do
        Dir.mktmpdir(nil, @temp_dir) do |dir|
          file = nil
          begin
            file = Tempfile.new(['test', 'json'], dir, encoding: 'UTF-8')
            file.close
            data = AeEasy::Test::Helper.load_json_file file.path
            assert_nil data
          ensure
            file.unlink unless file.nil?
          end
        end
      end

      it 'should get nil when not exists' do
        data = AeEasy::Test::Helper.load_json_file "./test/aaaaaa"
        assert_nil data
      end
    end

    it "should match element and partial filter when element include filter" do
      element = {'a' => 1, 'b' => 2, 'c' => '3', 'd' => ['d1', 'd2']}
      filter = {'b' => 2, 'c' => '3'}
      assert AeEasy::Test::Helper.match?(element, filter, exact_match: false)
    end

    it "should not match element and partial filter when different" do
      element = {'a' => 1, 'b' => 2, 'c' => '3', 'd' => ['d1', 'd2']}
      filter = {'b' => 2, 'c' => '4'}
      refute AeEasy::Test::Helper.match?(element, filter, exact_match: false)
    end

    it "should match element and exact filter when equal" do
      element = {'a' => 1, 'b' => 2, 'c' => '3', 'd' => ['d1', 'd2']}
      filter = {'a' => 1, 'b' => 2, 'c' => '3', 'd' => ['d1', 'd2']}
      assert AeEasy::Test::Helper.match?(element, filter, exact_match: true)
    end

    it "should not match element and exact filter when different" do
      element = {'a' => 1, 'b' => 2, 'c' => '3', 'd' => ['d1', 'd2']}
      filter = {'a' => 1, 'b' => 2, 'c' => '3', 'd' => ['d1', 'd3']}
      refute AeEasy::Test::Helper.match?(element, filter, exact_match: true)
    end

    it "should delete keys correctly" do
      element = {'a' => 1, 'b' => 2, 'c' => '3', 'd' => ['d1', 'd2']}
      keys = ['a', 'd']
      expected = {'b' => 2, 'c' => '3'}
      AeEasy::Test::Helper.delete_keys_from! element, keys
      assert_equal expected, element
    end

    it "should sanitize raw hash correctly" do
      element = {:a => 1, 'b' => 2, 'c' => '3', :d => ['d1', 'd2'], :e => 5}
      keys = ['b', 'e']
      expected = {'a' => 1, 'c' => '3', 'd' => ['d1', 'd2']}
      data = AeEasy::Test::Helper.sanitize element, skip_keys: keys
      assert_equal expected, data
    end

    it "should deep sanitize raw hash correctly" do
      element = {:a => 1, 'b' => 2, 'c' => '3', :d => {:da => 'd1', 'db' => 'd2'}, :e => 5}
      keys = ['b', 'e']
      expected = {'a' => 1, 'c' => '3', 'd' => {'da' => 'd1', 'db' => 'd2'}}
      data = AeEasy::Test::Helper.sanitize element, skip_keys: keys
      assert_equal expected, data
    end

    it "should deep sanitize raw hash with arrays correctly" do
      element = {:a => 1, 'b' => 2, 'c' => '3', :d => [{:da => 'd1', 'db' => 'd2'}], :e => 5}
      keys = ['b', 'e']
      expected = {'a' => 1, 'c' => '3', 'd' => [{'da' => 'd1', 'db' => 'd2'}]}
      data = AeEasy::Test::Helper.sanitize element, skip_keys: keys
      assert_equal expected, data
    end

    # TODO: Create these tests, right now it is just a copy and paste from the match? ones
    describe 'match collections' do
      it "should partial match elements within items" do
        items = [
          {'a' => 1, 'b' => 2, 'c' => '3', 'd' => ['d1', 'd2']},
          {'e' => '5', 'f' => '7', 'b' => 2, 'c' => '3'}
        ]
        expected = [
          {'b' => 2, 'c' => '3'},
          {'e' => '5', 'b' => 2, 'c' => '3'}
        ]
        assert AeEasy::Test::Helper.collection_match?(expected, items, exact_match: false)
      end

      it "should not partial match elements when different" do
        items = [
          {'a' => 1, 'b' => 2, 'c' => '3', 'd' => ['d1', 'd2']},
          {'e' => '5', 'f' => '7', 'b' => 2, 'c' => '3'}
        ]
        expected = [
          {'b' => 2, 'c' => '4'},
          {'e' => '5', 'b' => 2, 'c' => '3'}
        ]
        refute AeEasy::Test::Helper.collection_match?(expected, items, exact_match: false)
      end

      it "should exact match element when equal" do
        items = [
          {'a' => 1, 'b' => 2, 'c' => '3', 'd' => ['d1', 'd2']},
          {'e' => '5', 'f' => '7', 'b' => 2, 'c' => '3'}
        ]
        expected = [
          {'a' => 1, 'b' => 2, 'c' => '3', 'd' => ['d1', 'd2']},
          {'e' => '5', 'f' => '7', 'b' => 2, 'c' => '3'}
        ]
        assert AeEasy::Test::Helper.collection_match?(expected, items)
      end

      it "should not exact match elements when different" do
        items = [
          {'a' => 1, 'b' => 2, 'c' => '3', 'd' => ['d1', 'd2']},
          {'e' => '5', 'f' => '7', 'b' => 2, 'c' => '3'}
        ]
        expected = [
          {'a' => 1, 'b' => 2, 'c' => '4', 'd' => ['d1', 'd2']},
          {'e' => '5', 'f' => '7', 'b' => 2, 'c' => '3'}
        ]
        refute AeEasy::Test::Helper.collection_match?(expected, items)
      end

      it "should match exact elements when same length" do
        items = [
          {'a' => 1},
          {'b' => 2}
        ]
        expected = [
          {'a' => 1},
          {'b' => 2}
        ]
        assert AeEasy::Test::Helper.collection_match?(expected, items)
      end

      it "should not match exact elements when not same length" do
        items = [
          {'a' => 1},
          {'b' => 2}
        ]
        expected = [
          {'a' => 1},
          {'b' => 2},
          {'b' => 2}
        ]
        refute AeEasy::Test::Helper.collection_match?(expected, items)
        items = [
          {'a' => 1},
          {'b' => 2},
          {'b' => 2}
        ]
        expected = [
          {'a' => 1},
          {'b' => 2}
        ]
        refute AeEasy::Test::Helper.collection_match?(expected, items)
      end

      it "should match exact elements when indifferent about item length" do
        items = [
          {'a' => 1},
          {'b' => 2},
          {'c' => 3}
        ]
        expected = [
          {'a' => 1},
          {'b' => 2}
        ]
        assert AeEasy::Test::Helper.collection_match?(expected, items, same_count: false)
      end

      it "should not match exact elements when indifferent about item length" do
        items = [
          {'a' => 1},
          {'b' => 2}
        ]
        expected = [
          {'a' => 1},
          {'b' => 2},
          {'b' => 2}
        ]
        refute AeEasy::Test::Helper.collection_match?(expected, items)
        items = [
          {'a' => 1},
          {'b' => 2},
          {'b' => 2}
        ]
        expected = [
          {'a' => 1},
          {'b' => 2}
        ]
        refute AeEasy::Test::Helper.collection_match?(expected, items)
      end
    end
  end
end
