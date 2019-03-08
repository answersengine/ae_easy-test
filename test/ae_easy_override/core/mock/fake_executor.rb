require 'test_helper'

describe 'fake_executor' do
  before do
    Dir.mkdir('./tmp') unless Dir.exist?('./tmp')
    Dir.mkdir('./tmp/fake_executor') unless Dir.exist?('./tmp/fake_executor')
    @temp_dir = './tmp/fake_executor'
    @executor = Object.new
    class << @executor
      include AeEasy::Core::Mock::FakeExecutor
    end
  end

  describe 'unit test' do
    it 'should extend relative input directory' do
      @executor.root_input_dir = @temp_dir
      data = @executor.expand_relative_input 'aaa'
      expected = File.expand_path(File.join(@temp_dir, 'aaa'))
      refute_empty data
      assert_equal expected, data
    end
  end

  describe 'integration test' do
    before do
      @sample_data = sample_data = {
        content: '<html><body><h1 id="title">Hello world</h1><p id="content">This is the content.</p></body></html>',
        page: {"gid" => "p1", "url" => "https://a.example.com/abc", "headers" => {"Referer" => "https://a.example.com", "Cookie" => "abc:1" }},
        pages: [
          {"gid" => "p2", "url" => "https://b.example.com/abc", "headers" => {"Referer" => "https://b.example.com", "Cookie" => "abc:2" }},
          {"gid" => "p3", "url" => "https://c.example.com/abc", "headers" => {"Referer" => "https://c.example.com", "Cookie" => "abc:3" }}
        ],
        outputs: [
          {"_id" => "o1", "data_a" => "a1", "data_b" => "b1"},
          {"_id" => "o2", "data_a" => "a2", "data_b" => "b2"}
        ],
        expected_pages: [
          {"gid" => "p2", "url" => "https://b.example.com/abc", "headers" => {"Referer" => "https://b.example.com", "Cookie" => "abc:2" }},
          {"gid" => "p3", "url" => "https://c.example.com/abc", "headers" => {"Referer" => "https://c.example.com", "Cookie" => "abc:3" }},
          {"gid" => "p4", "url" => "https://d.example.com/abc", "headers" => {"Referer" => "https://d.example.com", "Cookie" => "abc:4" }}
        ],
        expected_outputs: [
          {"_id" => "o1", "data_a" => "a1", "data_b" => "b1"},
          {"_id" => "o2", "data_a" => "a2", "data_b" => "b2"},
          {"_id" => "o3", "data_a" => "a3", "data_b" => "b3"}
        ]
      }
      temp_dir = @temp_dir
      @temp_file = temp_file = Object.new
      metaclass = class << @temp_file; self; end
      metaclass.define_method(:non_json) do |file_name, contents, &block|
        Dir.mktmpdir(nil, temp_dir) do |dir|
          path = File.join(dir, file_name)
          begin
            file = File.open(path, 'w', encoding: 'UTF-8')
            file.write contents
            file.flush
            file.close
            block.call dir, file
          ensure
            File.delete path if File.exists? path
          end
        end
      end
      metaclass.define_method(:json) do |file_name, data, &block|
        contents = data.nil? ? '' : JSON.dump(data)
        temp_file.non_json "#{file_name}.json", contents, &block
      end
      metaclass.define_method(:content) do |&block|
        temp_file.non_json "content", sample_data[:content], &block
      end
      metaclass.define_method(:page) do |&block|
        temp_file.json "page", sample_data[:page], &block
      end
      metaclass.define_method(:pages) do |&block|
        temp_file.json "pages", sample_data[:page], &block
      end
      metaclass.define_method(:outputs) do |&block|
        temp_file.json "outputs", sample_data[:outputs], &block
      end
      metaclass.define_method(:expected_pages) do |&block|
        temp_file.json "expected_pages", sample_data[:expected_pages], &block
      end
      metaclass.define_method(:expected_outputs) do |&block|
        temp_file.json "expected_outputs", sample_data[:expected_outputs], &block
      end
    end

    it 'should load content correctly' do
      @temp_file.content do |dir, file|
        @executor.input_dir = dir
        @executor.load_input
      end
      expected = @sample_data[:content]
      assert_equal expected, @executor.content
    end

    it 'should load page correctly' do
      @temp_file.page do |dir, file|
        @executor.input_dir = dir
        @executor.load_input
      end
      expected = @sample_data[:page]
      assert AeEasy::Test::Helper.match?(@executor.page, expected, exact_match: false)
    end
  end
end
