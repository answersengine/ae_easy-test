require 'json'
require 'ae_easy/core'
require 'ae_easy_override/core'
require 'ae_easy/test/helper'
require 'ae_easy/test/rake'
require 'ae_easy/test/version'

module AeEasy
  module Test
    # Enable test mode inside executors.
    def self.enable_test_mode
      @@test_mode = true
    end

    # Disable test mode inside executors.
    def self.disable_test_mode
      @@test_mode = false
    end

    # Check if test mode is enabled inside executors.
    #
    # @return [Boolean] `true` when test mode enabled, else `false`.
    def self.test_mode?
      @@test_mode ||= false
    end

    # Verbose data log within caller backtrace.
    #
    # @param [String] message Message to display.
    # @param [Object,nil] data (nil) Data to inspect.
    # @param [Array] log_caller (nil) Log caller. Defaults to method caller.
    def self.verbose_log message, data = nil, log_caller = nil
      log_caller ||= caller
      caller_infos = log_caller.first.split ":"
      text = data.nil? ? 'nil' : data.inspect
      puts "\n#{caller_infos[0]}:#{caller_infos[1]} - #{message}#{text}\n\n"
    end

    # Verbose a match diff.
    #
    # @param [Hash] diff Match diff to verbose.
    # @param [Array] log_caller (nil) Log caller. Defaults to method caller.
    def self.verbose_match_diff type, diff, log_caller = nil
      unless diff[:saved].nil? || diff[:saved].count < 1
        verbose_log "Non matching saved #{type}: ", diff[:saved], log_caller
      end
      unless diff[:expected].nil? || diff[:expected].count < 1
        verbose_log "Non matching expected #{type}: ", diff[:expected], log_caller
      end
    end
  end
end
