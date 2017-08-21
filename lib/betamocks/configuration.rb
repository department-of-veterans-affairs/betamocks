# frozen_string_literal: true

require 'yaml'

module Betamocks
  class Configuration
    attr_accessor :config_path, :mocked_endpoints

    def cache_dir
      config[:cache_dir]
    end

    def mock_endpoint?(host, method, path)
      result = config[:services].select do |s|
        s[:base_urls].include?(host) && endpoints_match_path(s[:endpoints], method, path)
      end
      !result.empty?
    end

    def config
      @config ||= load_config
    end

    private

    def load_config
      raise ArgumentError, 'config.config_path not set' unless config_path
      raise IOError, 'config.config_path not found' unless File.exist? config_path
      YAML.load_file(@config_path)
    end

    def base_urls
      @base_urls ||= config[:services].map { |s| s[:base_urls] }.flatten
    end

    def endpoints_match_path(endpoints, method, path)
      result = endpoints.select { |e| /#{e[:path].gsub('/', '\/').gsub('*', '.*')}/ =~ path && e[:method] == method }
      result.count
    end
  end
end
