# frozen_string_literal: true

require 'active_support/all'
require 'faraday'
require 'fileutils'
require 'pp'
require_relative 'response_cache'

module Betamocks
  class Middleware < Faraday::Response::Middleware
    def call(env)
      @endpoint_config = find_endpoint_config(env)
      if @endpoint_config
        @cache = Betamocks::ResponseCache.new(env)
        response = @cache.load_response
        return response if response
      end
      super
    end

    def on_complete(env)
      cache_response(env) if @endpoint_config
    end

    private

    def find_endpoint_config(env)
      Betamocks.configuration.find_endpoint(env)
    end

    def cache_response(env)
      response = {
        method: env.method,
        body: env.body,
        headers: env.response_headers.as_json,
        status: env.status
      }
      @cache.save_response(response)
    end

    def cache_blank_response(env)
      date = Time.now.utc.strftime('%a, %d %b %Y %T UTC')
      response = {
        method: env.method,
        body: "{\"data\": {\"todo\": \"edit the response file #{@cache.file_path}\"}}",
        headers: {
          'date' => date,
          'access-control-allow-origin' => '*',
          'last-modified' => date,
          'x-served-from-cache' => 'false',
          'content-type' => 'application/json',
          'connection' => 'close'
        },
        status: 200
      }
      @cache.save_response(response)
      @cache.load_response
    end
  end
end
