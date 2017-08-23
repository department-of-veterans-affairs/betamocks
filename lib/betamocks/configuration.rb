# frozen_string_literal: true

require 'yaml'

module Betamocks
  class Configuration
    attr_accessor :config_path, :mocked_endpoints

    def cache_dir
      config[:cache_dir]
    end

    def find_endpoint(env)
      service = config[:services].select { |s| s[:base_urls].include?(env.url.host) }.first
      return nil unless service
      service[:endpoints].select { |e| matches_path(e, env.method, env.url.path) }.first
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

    def matches_path(endpoint, method, path)
      /#{endpoint[:path].gsub('/', '\/').gsub('*', '.*')}/ =~ path && endpoint[:method] == method
    end
  end
end
