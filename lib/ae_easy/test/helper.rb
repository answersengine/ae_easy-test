module AeEasy
  module Test
    module Helper
      # Load and return file contents when exists.
      #
      # @param [String] file_path File path to load.
      # @param [Boolean] should_exists (false) Enforce file existance validation.
      #
      # @return [String,nil] File contents.
      def self.load_file file_path, should_exists = false
        return nil unless should_exists || File.exists?(file_path)
        File.open(file_path, 'r', encoding: 'UTF-8').read
      end

      # Load and return file contents as json when exists.
      #
      # @param [String] file_path File path to load.
      # @param [Boolean] should_exists (false) Enforce file existance validation.
      #
      # @return [Hash,nil] Json file contents.
      def self.load_json_file file_path, should_exists = false
        file_content = load_file file_path, should_exists
        return nil if file_content.nil? || file_content.to_s.strip == ''
        JSON.parse(file_content)
      end

      # Delete keys from a hash.
      #
      # @param [Hash] hash Base hash to exclude from.
      # @param [Array] keys Keys to exclude.
      #
      # @return [Hash]
      def self.delete_keys_from! hash, keys
        return hash if keys.nil?
        keys.each{|k|hash.delete k}
        hash
      end

      # Sanitize a copy of the hash provided.
      #
      # @param [Hash] raw_hash Hash to sanitize.
      # @param [Hash] opts ({}) Configuration options.
      # @option opts [Boolean] :deep_stringify If `true` then stringify all hash
      #   keys including sublevels.
      # @option opts [Array,nil] :skip_keys (nil) Key array to delete from
      #   sanitized hash clone.
      #
      # @return [Hash] Sanitized hash clone.
      def self.sanitize raw_hash, opts
        opts = {
          deep_stringify: true,
          skip_keys: nil
        }.merge opts
        hash = (opts[:deep_stringify]) ?
          AeEasy::Core.deep_stringify_keys(raw_hash) :
          AeEasy::Core.deep_clone(raw_hash)
        delete_keys_from! hash, opts[:skip_keys]
      end

      # Check if an hash element match the filter.
      #
      # @param [Hash] element Element to match.
      # @param [Hash] filter Filters to apply.
      # @param [Hash] opts ({}) Configuration options.
      # @option opts [Boolean] :sanitize (true) Sanitize element and filters
      #   when `true`.
      # @option opts [Boolean] :deep_stringify If `true` then stringify all hash
      #   keys including sublevels before matching.
      # @option opts [Boolean] :exact_match (true) Filter should match element
      #   exactly.
      # @option opts [Array,nil] :skip_keys (nil) Keys to skip on match.
      #
      # @return [Boolean] `true` when element match filters, else `false`.
      def self.match? element, filter, opts = {}
        opts = {
          sanitize: true,
          deep_stringify: true,
          exact_match: true,
          skip_keys: nil
        }.merge opts

        # Sanitize element and filter when need
        if opts[:sanitize]
          element = sanitize element, opts
          filter = sanitize filter, opts
        end

        # Validate exact match when need
        exact_match = opts[:exact_match]
        return false if exact_match && element.keys.count != filter.keys.count

        # Match element filter
        filter.each do |k,v|
          return false if exact_match && !element.has_key?(k)
          return false if element[k] != v
        end
        true
      end

      # Generate a diff over 2 collections.
      #
      # @param [Array] items_a List of items to diff.
      # @param [Array] items_b List of items to diff.
      # @param [Hash] opts ({}) Configuration options.
      # @option opts [Boolean] :exact_match (true) Fragmenent should match
      #   element exactly.
      # @option opts [Boolean] :deep_stringify If `true` then stringify all hash
      #   keys including sublevels before matching.
      # @option opts [Boolean] :sanitize (true) Sanitize element and filters
      #   when `true`.
      # @option opts [Array,nil] :skip_keys (nil) Keys to skip on match.
      # @option opts [Symbol] :compare_way (:both) Comparison way sense:
      #   * `:both` Compare left and right.
      #   * `:right` Compare if `items_a` are inside `items_b`.
      #   * `:left` Compare if `items_b` are inside `items_a`.
      #
      # @return [Hash] Diff results as follows:
      #   * `[Array] :items_a` Diff items on `items_a` collection.
      #   * `[Array] :items_b` Diff items on `items_b` collection.
      #   * `[Boolean] :match` `true` when all items match else `false`.
      def self.collection_diff items_a, items_b, opts = {}
        # TODO: Improve this function
        #raise NotImplementedError.new('Current status WIP, don\'t use it for now.')
        opts = {
          exact_match: true,
          deep_stringify: true,
          sanitize: true,
          skip_keys: nil,
          compare_way: :both
        }.merge opts

        # Match collections items
        match = nil
        compare_right = opts[:compare_way] == :right || opts[:compare_way] == :both
        compare_left = opts[:compare_way] == :left || opts[:compare_way] == :both
        items_a = items_a.sort{|a,b|b.keys.count <=> a.keys.count}
        items_b = items_b.sort{|a,b|b.keys.count <=> a.keys.count}
        remaining_items = items_b + []
        not_found = []
        items_a.each do |item_a|
          found = remaining_items.find do |item_b|
            match = false
            match ||= match?(item_a, item_b, opts) if compare_left
            match ||= match?(item_b, item_a, opts) if compare_right
            match
          end

          # Save diff
          not_found << item_a if found.nil?
          remaining_items.delete found
        end

        # Send diff results
        {
          items_a: not_found,
          items_b: remaining_items,
          match: (not_found.count < 1 && remaining_items.count < 1)
        }
      end

      # Validate when an item collection match universe item collection.
      #
      # @param [Array] fragment Fragment of universe items to match.
      # @param [Array] universe List of items.
      # @param [Hash] opts ({}) Configuration options.
      # @option opts [Boolean] :exact_match (true) Fragmenent should match
      #   element exactly.
      # @option opts [Boolean] :same_count (true) Fragment item count should
      #   match universe item count exactly.
      # @option opts [Boolean] :deep_stringify If `true` then stringify all hash
      #   keys including sublevels before matching.
      # @option opts [Boolean] :sanitize (true) Sanitize element and filters
      #   when `true`.
      # @option opts [Array,nil] :skip_keys (nil) Keys to skip on match.
      # @option opts [Symbol] :compare_way (:both) Comparison way sense:
      #   * `:both` Compare left and right.
      #   * `:right` Compare if `items_a` are inside `items_b`.
      #   * `:left` Compare if `items_b` are inside `items_a`.
      #
      # @return [Boolean]
      def self.collection_match? fragment, universe, opts = {}
        opts = {
          exact_match: true,
          same_count: true,
          deep_stringify: true,
          sanitize: true,
          skip_keys: nil,
          compare_way: :both
        }.merge opts

        # False when item collections count are different
        return false if (opts[:match_quantity]) && fragment.count != universe.count

        diff = collection_diff fragment, universe, opts
        match = diff[:items_a].count < 1 && diff[:items_b].count < 1
        match
      end

      # Match two collections and calculate diff.
      #
      # @param [Array] items_a Item collection to match.
      # @param [Array] items_b Item collection to match.
      # @param [Hash] opts ({}) Configuration options.
      # @option opts [Array] :skip (nil) Keys to skip on match.
      # @option opts [Symbol] :compare_way (:left) Comparison way sense:
      #   * `:both` Compare left and right.
      #   * `:right` Compare if `items_a` are inside `items_b`.
      #   * `:left` Compare if `items_b` are inside `items_a`.
      #
      # @return [Hash] A hash with the following key pairs:
      #   * `[Hash] :diff` Diff results with `:items_a` and `:items_b` keys.
      #   * `[Boolean] :match` `true` when match else `false`.
      def self.match_collections items_a, items_b, opts = {}
        diff = collection_diff(
          items_a,
          items_b,
          skip_keys: opts[:skip],
          compare_way: :both
        )
        match = (diff[:items_a].count < 1 && diff[:items_b].count < 1)
        {diff: diff, match: diff[:match]}
      end
    end
  end
end
