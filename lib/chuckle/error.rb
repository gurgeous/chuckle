module Chuckle
  class Error < StandardError
    CURL_TIMEOUT = 28

    attr_accessor :response

    def initialize(msg, response)
      super(msg)
      self.response = response
    end

    def timeout?
      response.curl_exit_code == CURL_TIMEOUT
    end
  end
end
