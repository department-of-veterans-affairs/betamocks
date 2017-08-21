# frozen_string_literal: true

require 'betamocks/version'
require 'betamocks/configuration'
require 'betamocks/middleware'
require 'faraday'

module Betamocks
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end

Faraday::Response.register_middleware betamocks: Betamocks::Middleware
