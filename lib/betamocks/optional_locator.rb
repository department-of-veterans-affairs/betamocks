# frozen_string_literal: true
require 'rack'

module Betamocks
  class OptionalLocator
    attr_writer :env, :endpoint_config

    def initialize(env)
      @env = env
      @endpoint_config = Betamocks.configuration.find_endpoint(@env)
    end

    def generate
      matched_optional_locator = generate_optional_locator_dir(@endpoint_config[:cache_multiple_responses])
      return '' unless matched_optional_locator

      matched_optional_locator.gsub(/[^0-9a-z]/i, '')
    end

    private

    def generate_optional_locator_dir(locator_config)
      # Currently only works if optional locator is found in the body (must be same as the uid location)
      return unless locator_config && locator_config[:uid_location].to_sym == :body

      @env.body[/#{locator_config[:optional_code_locator]}/, 1]
    end
  end
end
