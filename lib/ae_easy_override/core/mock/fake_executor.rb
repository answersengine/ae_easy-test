module AeEasy
  module Core
    module Mock
      module FakeExecutor
        # Root input directory.
        attr_accessor :root_input_dir

        # Current assigned input directory.
        attr_accessor :input_dir

        # Expand a relative input directory.
        #
        # @param [String, nil] dir Relative input directory
        #
        # @return [String] Absolute path
        def expand_relative_input dir
          return nil if dir.nil?
          File.expand_path File.join(root_input_dir, dir)
        end

        # Load data into executor from options or input files.
        #
        # @param [Hash] opts ({}) Configuration options.
        # @option opts [String,nil] :input_dir (nil) Will load files from this
        #   directory. The files map as follows (file_name -> variable):
        #   ```
        #   content -> content
        #   page.json -> page
        #   vars.json -> page['vars']
        #   pages.json -> saved_pages
        #   outputs.json -> saved_outputs
        #   ```
        # @option opts [String,nil] :rel_dir (nil) Same as +:input_dir+ option
        #   but relative to root input directory (see #root_input_dir).
        # @option opts [String,nil] :content Content to load. It will override
        #   `content` file from input directory.
        # @option opts [Hash,nil] :page Page to load. It will override `page.json`
        #   from input directory.
        # @option opts [Hash,nil] :vars Variables to load. It will override
        #   `vars.json` from input directory.
        # @option opts [Hash,nil] :pages Pages to load. It will override
        #   `pages.json` from input directory.
        # @option opts [Hash,nil] :outputs Outputs to load. It will override
        #   `outputs.json` from input directory.
        #
        # @return [FakeExecutor]
        def load_input opts = {}
          opts = {
            rel_dir: nil,
            input_dir: nil,
            content: nil,
            page: nil,
            vars: nil,
            pages: nil,
            outputs: nil
          }.merge opts
          dir = self.input_dir = opts[:input_dir] || expand_relative_input(opts[:rel_dir]) || self.input_dir

          # Load overrides
          self.content = opts[:content]
          new_page = AeEasy::Core.deep_stringify_keys(opts[:page]) unless opts[:page].nil?
          save_pages opts[:pages] unless opts[:pages].nil?
          save_outputs opts[:outputs] unless opts[:outputs].nil?
          vars = nil
          vars = AeEasy::Core.deep_stringify_keys(opts[:vars]) unless opts[:vars]

          # Load input files
          unless dir.nil?
            self.content ||= AeEasy::Test::Helper.load_file(File.join(dir, 'content'))
            new_page ||= AeEasy::Test::Helper.load_json_file(File.join(dir, 'page.json'))
            input_pages = AeEasy::Test::Helper.load_json_file(File.join(dir, 'pages.json'))
            save_pages input_pages unless input_pages.nil?
            input_outputs = AeEasy::Test::Helper.load_json_file(File.join(dir, 'outputs.json'))
            save_outputs outputs unless input_outputs.nil?
            input_vars = AeEasy::Test::Helper.load_json_file(File.join(dir, 'vars.json'))
            vars ||= input_vars if opts[:page].nil?
          end

          # Load vars only when no page override and not nil
          self.page = new_page unless new_page.nil?
          page['vars'] = vars unless vars.nil?
          self
        end

        # Load failed content into executor from options or input files.
        #
        # @param [Hash] opts ({}) Configuration options.
        # @option opts [String,nil] :input_dir (nil) Will load files from this
        #   directory. The files map as follows (file_name -> variable):
        #   ```
        #   failed_content.json -> failed_content
        #   ```
        # @option opts [String,nil] :rel_dir (nil) Same as +:input_dir+ option
        #   but relative to root input directory (see #root_input_dir).
        # @option opts [Hash,nil] :failed_content Failed content to load. It
        #   will override `failed_content.json` from input directory.
        #
        # @return [FakeExecutor]
        def load_failed_content opts = {}
          opts = {
            rel_dir: nil,
            input_dir: nil,
            failed_content: nil
          }.merge opts
          dir = opts[:input_dir] || expand_relative_input(opts[:rel_dir]) || self.input_dir

          # Load overrides
          self.failed_content = opts[:failed_content]

          # Load input files
          unless dir.nil?
            self.failed_content ||= AeEasy::Test::Helper.load_file(File.join(dir, 'failed_content.json'))
          end

          self
        end

        # Load expected pages into executor from options or input files.
        #
        # @param [Hash] opts ({}) Configuration options.
        # @option opts [String,nil] :input_dir (nil) Will load files from this
        #   directory. The files map as follows (file_name -> variable):
        #   ```
        #   expected_pages.json -> saved_pages
        #   ```
        # @option opts [String,nil] :rel_dir (nil) Same as +:input_dir+ option
        #   but relative to root input directory (see #root_input_dir).
        # @option opts [Hash,nil] :pages Pages to load. It will override
        #   `expected_pages.json` from input directory.
        #
        # @return [FakeExecutor]
        def load_expected_pages opts = {}
          opts = {
            rel_dir: nil,
            input_dir: nil,
            pages: nil
          }.merge opts
          dir = opts[:input_dir] || expand_relative_input(opts[:rel_dir]) || self.input_dir

          # Load overrides
          save_pages opts[:pages] unless opts[:pages].nil?

          # Load input files
          unless dir.nil?
            expected_pages = AeEasy::Test::Helper.load_json_file(File.join(dir, 'expected_pages.json'))
            save_pages expected_pages unless expected_pages.nil?
          end

          self
        end

        # Load expected outputs into executor from options or input files.
        #
        # @param [Hash] opts ({}) Configuration options.
        # @option opts [String,nil] :input_dir (nil) Will load files from this
        #   directory. The files map as follows (file_name -> variable):
        #   ```
        #   expected_outputs.json -> saved_outputs
        #   ```
        # @option opts [String,nil] :rel_dir (nil) Same as +:input_dir+ option
        #   but relative to root input directory (see #root_input_dir).
        # @option opts [Hash,nil] :outputs Outputs to load. It will override
        #   `expected_outputs.json` from input directory.
        #
        # @return [FakeExecutor]
        def load_expected_outputs opts = {}
          opts = {
            rel_dir: nil,
            input_dir: nil,
            outputs: nil
          }.merge opts
          dir = opts[:input_dir] || expand_relative_input(opts[:rel_dir]) || self.input_dir

          # Load overrides
          save_outputs opts[:outputs] unless opts[:outputs].nil?

          # Load input files
          unless dir.nil?
            expected_outputs = AeEasy::Test::Helper.load_json_file(File.join(dir, 'expected_outputs.json'))
            save_outputs expected_outputs unless expected_outputs.nil?
          end

          self
        end

        # Create an executor based on the current executor type.
        #
        # @return [AeEasy::Core::Mock::FakeExecutor]
        def new_executor
          self.class.new
        end

        # Match expected pages.
        #
        # @param [Hash] opts ({}) Configuration options.
        # @option opts [String,nil] :input_dir (nil) Will load files from this
        #   directory. The files map as follows (file_name -> description):
        #   ```
        #   expected_pages.json -> expected pages to compare with saved_pages.
        #   ```
        # @option opts [String,nil] :rel_dir (nil) Same as +:input_dir+ option
        #   but relative to root input directory (see #root_input_dir).
        # @option opts [Hash,nil] :pages Expected pages to load. It will override
        #   `expected_pages.json` from input directory.
        # @option opts [Array] :skip_fields (nil) Fields to skip on match.
        # @option opts [Boolean] :default_skip_fields (true) Add `gid` and
        #   `job_id` to the `:skip_fields` list when `true`.
        #
        # @return [Hash] A hash with the following fields:
        #   * `[Boolean] match` `true` when match, `false` when diff.
        #   * `[Hash] saved` Non matching saved pages.
        #   * `[Hash] expected` Non matching expected pages.
        def match_expected_pages opts = {}
          opts = {
            rel_dir: nil,
            input_dir: nil,
            pages: nil,
            skip_fields: [],
            default_skip_fields: true,
          }.merge opts
          opts[:input_dir] ||= input_dir

          # Expected context
          expected_opts = {}.merge opts
          expected_opts[:input_dir] ||= input_dir
          expected = new_executor
          expected.root_input_dir = root_input_dir
          expected.load_expected_pages expected_opts

          # Config skip fields
          skip_fields = opts[:skip_fields]
          skip_fields += ['gid', 'job_id'] if opts[:default_skip_fields]
          skip_fields.uniq!

          # Diff
          diff = AeEasy::Test::Helper.match_collections(
            saved_pages,
            expected.saved_pages,
            skip: skip_fields,
            compare_way: :left
          )
          {
            match: diff[:match],
            saved: diff[:diff][:items_a],
            expected: diff[:diff][:items_b]
          }
        end

        # Match saved pages with expected and verbose diff.
        # {AeEasy::Test::Helper#match_expected}
        # @option opts [Array] :log_caller (nil) Log caller. Defaults to method
        #   `caller`.
        #
        # @return [Boolean] `true` when pass, else `false`.
        def should_match_pages opts = {}
          flush
          diff = match_expected_pages opts
          log_caller = opts[:log_caller] || ([] + caller)
          unless diff[:match]
            AeEasy::Test.verbose_match_diff 'pages', diff, log_caller
          end
          diff[:match]
        end

        # Match expected outputs.
        #
        # @param [Hash] opts ({}) Configuration options.
        # @option opts [String,nil] :input_dir (nil) Will load files from this
        #   directory. The files map as follows (file_name -> description):
        #   ```
        #   expected_outputs.json -> expected outputs to compare with saved_outputs.
        #   ```
        # @option opts [String,nil] :rel_dir (nil) Same as +:input_dir+ option
        #   but relative to root input directory (see #root_input_dir).
        # @option opts [Hash,nil] :outputs Expected outputs to load. It will
        #   override `expected_outputs.json` from input directory.
        # @option opts [Array] :skip_fields (nil) Fields to skip on match.
        # @option opts [Boolean] :default_skip_fields (true) Add `_gid`,
        #   `_job_id` and `_created_at` to the `:skip_fields` list when `true`.
        #
        # @return [Hash] A hash with the following structure:
        #   * `[Boolean] match` `true` when match, `false` when diff.
        #   * `[Hash] expected` Non matching expected outputs.
        #   * `[Hash] saved` Non matching saved outputs.
        def match_expected_outputs opts = {}
          opts = {
            rel_dir: nil,
            input_dir: nil,
            outputs: nil,
            skip_fields: [],
            default_skip_fields: true,
          }.merge opts

          # Expected context
          expected_opts = {}.merge opts
          expected_opts[:input_dir] ||= input_dir
          expected = new_executor
          expected.root_input_dir = root_input_dir
          expected.load_expected_outputs expected_opts

          # Config skip fields
          skip_fields = opts[:skip_fields]
          skip_fields += ['_created_at', '_gid', '_job_id'] if opts[:default_skip_fields]
          skip_fields.uniq!

          # Diff
          diff = AeEasy::Test::Helper.match_collections(
            saved_outputs,
            expected.saved_outputs,
            skip: skip_fields,
            compare_way: :left
          )
          {
            match: diff[:match],
            saved: diff[:diff][:items_a],
            expected: diff[:diff][:items_b]
          }
        end

        # Match saved outputs with expected and verbose diff.
        # {AeEasy::Test::Helper#match_expected_outputs}
        # @option opts [Array] :log_caller (nil) Log caller. Defaults to method
        #   `caller`.
        #
        # @return [Boolean] `true` when pass, else `false`.
        def should_match_outputs opts = {}
          flush
          diff = match_expected_outputs opts
          log_caller = opts[:log_caller] || ([] + caller)
          unless diff[:match]
            AeEasy::Test.verbose_match_diff 'outputs', diff, log_caller
          end
          diff[:match]
        end
      end
    end
  end
end
