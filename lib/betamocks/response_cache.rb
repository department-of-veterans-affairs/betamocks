# frozen_string_literal: true

require_relative 'uid'

module Betamocks
  class ResponseCache
    attr_writer :config, :env

    def initialize(env:, config: nil)
      @env = env
      @config = config
      @generated_file_name = generate_file_name
    end

    def load_response
      raise IOError, "Betamocks cache_dir: [#{Betamocks.configuration.cache_dir}], does not exist" unless File.directory?(Betamocks.configuration.cache_dir)
      if File.exist?(file_path(@generated_file_name))
        Faraday::Response.new(load_env(@generated_file_name))
      else
        Betamocks.logger.warn "Mock response not found: [#{file_path(@generated_file_name)}]"
      end
    end

    def default_response
      raise IOError, "Betamocks default response requested but none exist. Please create one at: [#{file_path('default.yml')}]." unless File.exist?(file_path('default.yml'))
      Faraday::Response.new(load_env('default.yml'))
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

    def load_env(file_name)
      cached_env = YAML.load_file(file_path(file_name))
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

    def file_path(file_name = nil)
      File.join(dir_path, file_name || @generated_file_name)
    end

    def generate_file_name
      name = @config[:file_path].split('/').last
      @config.dig(:cache_multiple_responses) ? "#{Uid.new(@env).generate}.yml" : "#{name}.yml"
    end
  end
end
