# frozen_string_literal: true

require_relative 'checksum'

module Betamocks
  class ResponseCache
    attr_writer :config, :env, :file_name

    def initialize(env:, config: nil)
      @env = env
      @config = config
      @file_name = generate_file_name
    end

    def load_response
      Faraday::Response.new(load_env) if File.exist?(file_path)
    end

    def save_response(env)
      response = {
        method: env.method,
        body: env.body,
        headers: env.response_headers.as_json,
        status: env.status
      }
      FileUtils.mkdir_p(dir_path) unless File.directory?(dir_path)
      File.open(file_path, 'w') { |f| f.write(response.to_yaml) }
    end

    private

    def load_env
      cached_env = YAML.load_file(file_path)
      @env.method = cached_env[:method]
      @env.body = cached_env[:body]
      @env.response_headers = cached_env[:headers]
      @env.status = cached_env[:status]
      @env
    end

    def dir_path
      File.join(
        Betamocks.configuration.cache_dir,
        @config[:file_path]
      )
    end

    def file_path
      File.join(dir_path, @file_name)
    end

    def generate_file_name
      tail = File.basename(@env.url.path)
      @config[:cache_multiple_responses] ? "#{tail}_#{Checksum.generate(@env)}.yml" : "#{tail}.yml"
    end
  end
end
