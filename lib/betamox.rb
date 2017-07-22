require 'betamox/version'
require 'betamox/configuration'
require 'betamox/middleware'
require 'faraday'

module Betamox
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

Faraday::Response.register_middleware betamox: Betamox::Middleware
