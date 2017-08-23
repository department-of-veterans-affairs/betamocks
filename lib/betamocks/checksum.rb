# frozen_string_literal: true

require 'adler32'

module Betamocks
  class Checksum
    def self.generate(env)
      method = env.method.to_s
      url = env.url.to_s
      headers = filter_headers_string(env)
      body = if env.method == :post
               filter_body(env)
             else
               ''
             end
      string = "#{method}#{url}#{headers}#{body}"
      Adler32.checksum(string)
    end

    def self.filter_body(env)
      body = env.body.dup
      endpoint = Betamocks.configuration.find_endpoint(env)
      endpoint[:timestamp_regex].each do |tr|
        body.sub!(/#{tr}/) { |match| match.sub(Regexp.last_match[1], '*') }
      end
      body
    end

    def self.filter_headers_string(env)
      env.request_headers.reject { |_k, v| date_string? v }.to_s
    end

    def self.date_string?(string)
      DateTime.parse(string).utc
      true
    rescue ArgumentError
      false
    end
  end
end
