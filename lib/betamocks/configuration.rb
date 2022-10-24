# frozen_string_literal: true

require 'yaml'

module Betamocks
  class Configuration
    attr_accessor :cache_dir, :mocked_endpoints, :services_config
    attr_writer :recording, :enabled

    def find_endpoint(env)
      service = service_by_host_port(env)
      return nil unless service
      # TODO raise if service.size > 1 ?
      
      endpoints = service[:endpoints].select { |e| matches_path(e, env.method, env.url.path) }
      return nil unless endpoints
      return endpoints.first if endpoints.size == 1

      # one path + http verb may be used for multiple resources
      endpoints = endpoints.select { |e| matches_request_params(e, env) }
      return nil unless endpoints
      return endpoints.first if endpoints.size == 1

      raise ArgumentError, "Unable to uniquely identify request! Please check your services config.  Matched endpoints: [#{endpoints.to_s}]"
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
      /\A#{endpoint[:path].gsub('/', '\/').gsub('*', '[^\/]*').tr('()', '')}\z/ =~ path && endpoint[:method] == method
    end

    def matches_request_params(endpoint, env)
      endpoint_config = endpoint.dig(:cache_multiple_responses)
      return false if endpoint_config.nil?

      location = endpoint_config[:uid_location].to_sym
      locator = endpoint_config[:uid_locator]

      optional_locator = endpoint_config[:optional_code_locator]

      case location
      when :body
        /#{locator}/ =~ env.body && /#{optional_locator}/ =~ env.body
      when :header
        return false # TODO
      when :query
        return false # TODO
      when :url
        return false # TODO
      else
        message = "#{location} is not a valid location for a uid try 'body', 'headers', 'query', or 'url' instead"
        raise ArgumentError, message
      end
    end
  end
end
