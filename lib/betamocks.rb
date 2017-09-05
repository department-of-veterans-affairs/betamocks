# frozen_string_literal: true

require 'betamocks/version'
require 'betamocks/configuration'
require 'betamocks/middleware'
require 'faraday'

module Betamocks
  class << self
    attr_writer :configuration, :logger

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def logger
      @logger ||= Logger.new($stdout).tap do |log|
        log.progname = self.name
      end
    end
  end
end

Faraday::Response.register_middleware betamocks: Betamocks::Middleware
