require 'faraday'

#TODO: cache key: by header or body value

module Betamox
  class Middleware < Faraday::Response::Middleware
    def call(env)
      puts Betamox.configuration
      # puts env.url.host
      # puts env.url.path.gsub('/', '_')
      # env.status = 200
      # env.body = '{"foo": {"funk": 5}}'
      # puts env.to_yaml
      # Faraday::Response.new(env)
      hash = Digest::MD5.hexdigest env.to_s
      puts env.url.host
      puts env.url.path.gsub('/', '_')
      super
    end

    def on_complete(env)
      # env.status = 200
      # env.body = '{"foo": {"funk": 5}}'
      puts env.to_yaml
      env
    end
  end
end
