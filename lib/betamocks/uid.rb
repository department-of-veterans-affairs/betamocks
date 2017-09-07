# frozen_string_literal: true
require 'rack'

module Betamocks
  class Uid
    attr_writer :env, :endpoint_config

    def initialize(env)
      @env = env
      @endpoint_config = Betamocks.configuration.find_endpoint(@env)
    end

    def generate
      uid_config = @endpoint_config.dig(:cache_multiple_responses)
      generate_uid(uid_config)
    end

    private

    def generate_uid(uid_config)
      location = uid_config[:uid_location].to_sym
      locator = uid_config[:uid_locator]
      case location
      when :body
        @env.body[/#{locator}/, 1]
      when :header
        @env.request_headers[locator]
      when :query
        h = Rack::Utils.parse_nested_query(@env.url.query)
        h[locator]
      when :url
        @env.url.path[/#{locator}/, 1]
      else
        message = "#{location} is not a valid location for a uid try 'body', 'headers', or 'uri' instead"
        raise ArgumentError, message
      end
    end
  end
end
