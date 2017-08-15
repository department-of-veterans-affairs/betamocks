require 'adler32'

module Betamocks
  class ResponseCache
    attr_accessor :env, :file_path

    def initialize(env)
      @env = env
      @file_path = create_file_path
    end

    def load_response
      Faraday::Response.new(load_env) if File.exist?(@file_path)
    end

    def save_response(response)
      File.open(@file_path, 'w') { |f| f.write(response.to_yaml) }
    end

    private

    def create_file_path
      dir_path = find_or_create_cache_dir
      tail = File.basename(env.url.path)
      checksum = "#{tail}-#{Adler32.checksum(env.to_s)}"
      File.join(dir_path, "#{checksum}.yml")
    end

    def find_or_create_cache_dir
      path = File.join(
        Betamocks.configuration.cache_dir,
        @env.url.host,
        @env.url.path.split('/')[0...-1]
      )
      FileUtils.mkdir_p(path) unless File.directory?(path)
      path
    end

    def load_env
      cached_env = YAML.load_file(@file_path)
      @env.method = cached_env[:method]
      @env.body = cached_env[:body]
      @env.response_headers = cached_env[:headers]
      @env.status = cached_env[:status]
      @env
    end
  end
end
