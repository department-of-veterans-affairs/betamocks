require_relative './response_store'
require 'faraday'
require 'fileutils'
require 'pp'

#TODO: cache key: by header or body value

module Betamocks
  class Middleware < Faraday::Response::Middleware
    def call(env)
      # puts env.to_yaml
      if Betamocks.configuration.mock_endpoint?(env.url.host, env.url.path)
        path = cache_path(env)
        FileUtils.mkdir_p(path) unless File.directory?(path)
        @response_cache_path = cache_file(env, path)
        return Faraday::Response.new(YAML.load_file(@response_cache_path)) if File.exist?(@response_cache_path)
      end
      super
    end

    def on_complete(env)
      response_store = {
        method: env.method,
        body: env.body,
        request_headers: env.request_headers,
        status: env.status
      }
      # File.open(@response_cache_path, 'w') { |f| f.write(env.to_yaml) }
      File.open(@response_cache_path, 'w') { |f| f.write(response_store.to_yaml) }
      puts "\n\n\n"
      puts response_store.to_yaml
      puts "\n\n\n"
      env
    end

    private

    def cache_path(env)
      File.join(
        Betamocks.configuration.cache_dir,
        env.url.host,
        env.url.path
      )
    end

    def cache_file(env, path)
      hex = Digest::MD5.hexdigest env.to_s
      File.join(path, "#{hex}.yml")
    end
  end
end
