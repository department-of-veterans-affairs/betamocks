# frozen_string_literal: true

require 'yaml'

module Betamocks
  class Configuration
    attr_accessor :cache_dir, :mocked_endpoints, :services_config
    attr_writer :recording, :enabled

    def find_endpoint(env)
      service = service_by_host_port(env)
      return nil unless service
      service[:endpoints].select { |e| matches_path(e, env.method, env.url.path) }.first
    end

    def config
      @config ||= load_config
    end

    def enabled=(value)
      @enabled = value.to_s == 'true'
    end

    def recording=(value)
      @recording = value.to_s == 'true'
    end

    def enabled?
      return false if [ENV['RAILS_ENV'], ENV['RACK_ENV']].include? 'test'
      @enabled
    end

    def recording?
      @recording || false
    end

    private

    def load_config
      raise ArgumentError, 'config.services_config not set' unless @services_config
      raise IOError, 'config.services_config file not found' unless File.exist? @services_config
      YAML.load(ERB.new(File.read(@services_config)).result)
    end

    def base_urls
      @base_urls ||= config[:services].map { |s| s[:base_urls] }.flatten
    end

    def service_by_host_port(env)
      config[:services].select { |s| s[:base_uri] == "#{env.url.host}:#{env.url.port}" }.first
    end

    def matches_path(endpoint, method, path)
      /\A#{endpoint[:path].gsub('/', '\/').gsub('*', '[^\/]*')}\z/ =~ path && endpoint[:method] == method
    end
  end
end
