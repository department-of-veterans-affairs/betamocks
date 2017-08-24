# frozen_string_literal: true

require 'active_support/all'
require 'faraday'
require 'fileutils'
require 'pp'
require_relative 'response_cache'

module Betamocks
  class Middleware < Faraday::Response::Middleware
    def call(env)
      return super unless Betamocks.configuration.enabled
      @endpoint_config = Betamocks.configuration.find_endpoint(env)
      if @endpoint_config
        @response_cache = Betamocks::ResponseCache.new(env)
        response = @response_cache.load_response
        return response if response
      end
      super
    end

    def on_complete(env)
      return unless Betamocks.configuration.enabled
      @response_cache.save_response(env) if @endpoint_config
    end
  end
end
