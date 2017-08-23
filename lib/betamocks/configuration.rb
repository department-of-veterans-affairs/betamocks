# frozen_string_literal: true

require 'yaml'

module Betamocks
  class Configuration
    attr_accessor :cache_dir, :enabled, :mocked_endpoints, :services_config

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
      raise ArgumentError, 'config.services_config not set' unless @services_config
      raise IOError, 'config.services_config file not found' unless File.exist? @services_config
      YAML.load_file(@services_config)
    end

    def base_urls
      @base_urls ||= config[:services].map { |s| s[:base_urls] }.flatten
    end

    def matches_path(endpoint, method, path)
      /#{endpoint[:path].gsub('/', '\/').gsub('*', '.*')}/ =~ path && endpoint[:method] == method
    end
  end
end
