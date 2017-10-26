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
        raise_error(env, @endpoint_config) if @endpoint_config[:error]
        @response_cache = Betamocks::ResponseCache.new(env: env, config: @endpoint_config)
        response = @response_cache.load_response
        return response if response
        return @response_cache.load_response('default.yml') if Betamocks.configuration.mode == Betamocks::Configuration::PLAYBACK
      end
      super
    end

    def on_complete(env)
      return unless Betamocks.configuration.enabled && Betamocks.configuration.mode == Betamocks::Configuration::RECORDING
      @response_cache.save_response(env) if @endpoint_config
    end

    def raise_error(env, endpoint_config)
      status = endpoint_config.dig(:error, :status).to_i
      body = endpoint_config.dig(:error, :body)

      Betamocks.logger.info "raising a mock #{status} error for #{env.url}"

      case status
      when 404
        raise Faraday::Error::ResourceNotFound, status: status, body: body
      when 407
        raise Faraday::Error::ConnectionFailed, '407 "Proxy Authentication Required"'
      else
        raise Faraday::Error::ClientError, status: status, body: body
      end
    end
  end
end
