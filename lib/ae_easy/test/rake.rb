require 'rake'

module AeEasy
  module Test
    # Record rake task generator. It allows AnswersEngine pages snapshots to be
    #   recorded for an easy way to perform integration tests.
    class RecordTask
      # Scraper name to be used to get job_id.
      #
      # @return [String,nil]
      attr_accessor :scraper_name

      # Will show logs on stdout when enabled (see #enable_verbose and
      #   #disable_verbose)
      #
      # @return [Boolean] `true` when enabled, else `false`.
      #
      # @note Default value is `true`.
      def verbose?
        @verbose = true if @verbose.nil?
        @verbose
      end

      # Enable verbose.
      def enable_verbose
        @verbose = true
      end

      # Disable verbose.
      def disable_verbose
        @verbose = false
      end

      # Job id to be used on page recording.
      #
      # @return [Integer,nil]
      def job_id
        @job_id ||= nil
      end

      # Set job id.
      #
      # @param [Integer,nil] value Job id.
      def job_id= value
        @job_id = value
      end

      # Log text into stdout when verbose is enabled (see #verbose?).
      #
      # @param [String] text Message to be log.
      def log text
        puts text unless verbose?
      end

      # Root directory to record pages. Useful to reduce input map fingerprint.
      #
      # @return [String,nil]
      def root_dir
        @root ||= nil
      end

      # An array of input maps to configure what gid record will be saved into
      #   each directory. It uses absolute paths when #root_dir is nil, and
      #   relative paths when it has been assigned.
      #
      # @return [Array] Map structure is as follows (see #record_outputs for
      #   details about `input_map[][:filter][:outputs]` options):
      #   ```
      #   [
      #     {
      #       gid:'my-gid-123abc',
      #       dir:'/path/to/input/directory',
      #       record_content: true/false, # Default: true
      #       record_failed_content: true/false, # Default: true,
      #       record_page: true/false, # Default: true
      #       record_vars: true/false, # Default: false
      #       filters: {
      #         outputs: {
      #           # Output filters
      #         }
      #       }
      #     }, {
      #       # ...
      #     }
      #   ]
      def input_map
        @input_map ||= []
      end

      # AnswersEngine executor used to get the data to be recorded.
      #
      # @return [AnswersEngine::Scraper::Executor]
      def executor
        @executor ||= AnswersEngine::Scraper::Executor.new
      end

      # Ensures that job_id exists. If #scraper_name is present and no #job_id
      #   was specified, then it will get the latest `job_id` for the
      #   `scraper_name` provided.
      #
      # @return [Integer,nil] Job id.
      def ensure_job_id
        if job_id.nil && !scraper_name.nil?
          log "Retriving \"job_id\" from scraper \"#{scraper_name}\""
          job_id = @executor.get_job_id scraper_name.strip
        end
        log(job_id.nil? ? 'No "job_id" was specified.' : "Using \"job_id\" #{job_id}.")
        job_id
      end

      # Record a content into a file only when the content is not null. It will
      #   delete the existing file regardless if a new file will be created or
      #   not.
      #
      # @param [String] path File path to override.
      # @param [String,nil] content Content to be saved on the file.
      # @yieldparam [File] file File to save the data into.
      def record_file path, content, &block
        if File.exists? path
          log "Deleting old \"#{path}\" file..."
          File.delete path
          log "Done."
        end
        if content.nil? && block.nil?
          log 'Null content detected, skip file.'
          return
        end
        log "Creating \"#{page}\" file..."
        File.open(path) do |file|
          file.write content unless content.nil?
          block.call file unless block.nil?
        end
        log "Done."
      end

      # Record a page raw content (HTML, XML, excel, zip, etc.) into `content`
      #   file within the provided directory.
      #
      # @param [String] gid Page `gid` to retrieve the data from.
      # @param [String] dir Directory to save file into.
      def record_content gid, dir
        content = executor.get_content gid
        path = File.join(dir, 'content')
        record_file path, content
      end

      # Record a page raw failed content (HTML, XML, excel, zip, etc.) into
      #   `failed_content` file within the provided directory.
      #
      # @param [String] gid Page `gid` to retrieve the data from.
      # @param [String] dir Directory to save file into.
      def record_failed_content gid, dir
        content = executor.get_failed_content gid
        path = File.join(dir, 'failed_content')
        record_file path, content
      end

      # Record a page's global or job definition (JSON) into `page.json` file
      #   within the provided directory.
      #
      # @param [String] gid Page `gid` to retrieve the data from.
      # @param [String] dir Directory to save file into.
      #
      # @note It will prefer job page definition over global page unless no
      #   `job_id` (see #job_id) or `scraper_name` (see #scraper_name) is
      #   defined.
      def record_page gid, dir
        if job_id.nil?
          log 'Warning: No "scraper_name" or "job_id" was specified, will use global page instead job page.'
        end
        @executor.gid = gid
        @executor.job_id = job_id
        page = @executor.init_page()
        content = JSON.pretty_generate page
        path = File.join(dir, 'page.json')
        record_file path, content
      end

      # Record a page's vars from job page definition (JSON) into `vars.json`
      #   file within the provided directory.
      #
      # @param [String] gid Page `gid` to retrieve the data from.
      # @param [String] dir Directory to save file into.
      #
      # @note It will skip it if no `job_id` (see #job_id) or `scraper_name`
      #   (see #scraper_name) is defined.
      def record_vars gid, dir
        if job_id.nil?
          log 'Warning: No "scraper_name" or "job_id" was specified, will skip vars.'
          return
        end
        @executor.gid = gid
        @executor.job_id = job_id
        page = @executor.init_page()
        content = JSON.pretty_generate page['vars']
        path = File.join(dir, 'vars.json')
        record_file path, content
      end

      # Record a collection of outputs (JSON) into `outputs.json` file within
      #   the provided directory using filters on AnswersEngine executor
      #   `find_outputs` method to retrieve all matching outputs regardless of
      #   pagination.
      #
      # @param [Hash, nil] filter (nil) Filters to retrieve `outputs`.
      # @option filter [String] :collection ('default') Output collection.
      # @option filter [Hash] :query ({}) Query that outputs should match.
      # @option filter [Hash] :opts ({}) `find_outputs` configuration options
      #   (see AnswersEngine::Scraper::Executor#find_outputs for details).
      #
      # @note Will skip when `nil` is provided as filters.
      def record_outputs filter = nil
        if filter.nil?
          log 'Skip outputs, no filter detected.'
          return
        end
        path = File.join(dir, 'outputs.json')
        filter = {
          collection: 'default',
          query: {},
          opts: {}
        }.merge filter

        record_file path, nil do |file|
          count = 0
          page = 1
          outputs = @executor.find_outputs(
            filter[:collection],
            filter[:query],
            page,
            100,
            filter[:opts]
          )

          file.write '['
          while !outputs.nil? && outputs.count > 0
            page += 1
            outputs.each do |output|
              f.write ',' if count > 0
              count += 1
              file.write JSON.pretty_generate(output)
            end
            outputs = @executor.find_outputs(
              filter[:collection],
              filter[:query],
              page,
              100,
              filter[:opts]
            )
          end
          file.write ']'
        end
      end

      # Record a page data into a specific directory.
      #
      # @param [Hash] map ({}) Input map configuration.
      # @option map [String] :gid Page `gid` to retrieve the data from.
      # @option map [String] :dir Directory to save file into.
      # @option map [Boolean] :record_content (true) Record content when `true`.
      # @option map [Boolean] :record_failed_content (true) Record failed_cntent
      #   when `true`.
      # @option map [Boolean] :record_page (true) Record page when `true`.
      # @option map [Boolean] :record_vars (false) Record vars when `true`.
      # @option map [Hash] :filters ({outputs:nil}) Filter hash for outputs
      #   recording, will record only when a filter is specify.
      def record map
        map = {
          gid: nil,
          dir: nil,
          record_content: true,
          record_failed_content: true,
          record_page: true,
          record_vars: false,
          filters: {
            outputs: nil
          }
        }.merge map

        gid = map[:gid].to_s.strip
        raise ArgumentError.new('"gid" can\'t be empty') if gid == ''
        dir = map[:dir].to_s.strip
        raise ArgumentError.new('"dir" can\'t be empty') if dir == ''
        dir = File.join root_dir, dir unless root_dir.nil? || root_dir.strip == ''
        dir = File.expand_path dir
        unless Dir.exist? dir
          raise ArgumentError.new "\"#{dir}\" don't exists or is not a directory."
        end
        log "Recording on \"#{dir}\" directory..."

        record_content gid, dir if map[:content]
        record_failed_content gid, dir if map[:failed_content]
        record_page gid, dir if map[:page]
        record_vars gid, dir if map[:vars]

        filters = map[:filters]
        unless filters.nil?
          record_outputs filters[:outputs] unless filters[:outputs].nil?
        end
        log "Finish recording \"#{dir}\" directory."
      end

      # Record pages from an input map collection.
      #
      # @param [Array] input_map Input map collection (see #input_map for
      #   structure).
      def record_pages input_map
        ensure_job_id
        input_map.each do |map|

          record_page gid, dir, opts
        end
      end

      # Create the record rake task
      def create_task
        namespace 'ae_easy' do
          desc "Generates input files by gid into the configured directories, use these on context loading."
          task :record_pages do
            record_pages input_map
          end
        end
      end

      # Initialize record task. Use block to configure record task.
      #
      # @yieldparam [AeEasy::Test::RecordTask] task Self.
      def initialize &block
        verbose = nil
        block.call self unless block.nil?
        create_task
      end
    end
  end
end
