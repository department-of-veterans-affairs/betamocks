require 'active_support/all'

module Betamocks
  class ResponseStore
    attr_accessor :method, :body, :headers, :status

    def initialize(method, body, headers, status)
      @method = method
      @body = body
      @headers = headers.as_json
      @status = status
    end

    def to_yaml
      YAML.dump({
        method: method,
        body: body,
        headers: headers,
        status: status
      })
    end
  end
end
