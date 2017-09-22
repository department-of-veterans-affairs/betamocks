# frozen_string_literal: true

require_relative 'uid'

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
    rescue Psych::SyntaxError => e
      Betamocks.logger.error "error loading cache file: #{e.message}"
      raise e
    end

    def dir_path
      file_path_array = @config[:file_path].split('/')
      File.join(
        Betamocks.configuration.cache_dir,
        @config.dig(:cache_multiple_responses) ? file_path_array : file_path_array[0...-1]
      )
    end

    def file_path
      File.join(dir_path, @file_name)
    end

    def generate_file_name
      name = @config[:file_path].split('/').last
      @config.dig(:cache_multiple_responses) ? "#{Uid.new(@env).generate}.yml" : "#{name}.yml"
    end
  end
end
