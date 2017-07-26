module Betamocks
  class ResponseStore
    attr_accessor :method, :body, :headers, :status

    def initialize(method, body, headers, status)
      @method = method
      @body = body
      @headers = headers
      @status = status
    end
  end
end
