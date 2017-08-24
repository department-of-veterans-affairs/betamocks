# frozen_string_literal: true

require_relative 'checksum'

module Betamocks
  class ResponseCache
    attr_writer :env, :file_name

    def initialize(env)
      @env = env
      @file_name = generate_file_name(env)
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
        @env.url.host,
        @env.url.path.split('/')[0...-1]
      )
    end

    def file_path
      File.join(dir_path, @file_name)
    end

    def generate_file_name(env)
      tail = File.basename(env.url.path)
      "#{tail}_#{Checksum.generate(env)}.yml"
    end
  end
end
