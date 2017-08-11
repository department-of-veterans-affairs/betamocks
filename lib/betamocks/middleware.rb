require 'active_support/all'
require 'faraday'
require 'fileutils'
require 'pp'

module Betamocks
  class Middleware < Faraday::Response::Middleware
    def call(env)
      if Betamocks.configuration.mock_endpoint?(env.url.host, env.url.path)
        @response_cache_path = cache_file_path(env)
        return Faraday::Response.new(load_env(env)) if File.exist?(@response_cache_path)
      end
      super
    end

    def on_complete(env)
      cache(env)
      env
    end

    private

    def cache_file_path(env)
      dir_path = find_or_create_cache_dir(env)
      hex = Digest::MD5.hexdigest env.to_s
      File.join(dir_path, "#{hex}.yml")
    end

    def find_or_create_cache_dir(env)
      path = File.join(
        Betamocks.configuration.cache_dir,
        env.url.host,
        env.url.path
      )
      FileUtils.mkdir_p(path) unless File.directory?(path)
      path
    end

    def cache(env)
      response_store = {
        method: env.method,
        body: env.body,
        headers: env.response_headers.as_json,
        status: env.status
      }
      File.open(@response_cache_path, 'w') { |f| f.write(response_store.to_yaml) }
    end

    def load_env(env)
      cached_env = YAML.load_file(@response_cache_path)
      env.method = cached_env[:method]
      env.body = cached_env[:body]
      env.response_headers = cached_env[:headers]
      env.status = cached_env[:status]
      env
    end
  end
end
