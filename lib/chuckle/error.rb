module Chuckle
  class Error < StandardError
    CURL_TIMEOUT = 28

    attr_accessor :request, :curl_exit_code, :response

    def timeout?
      curl_exit_code == CURL_TIMEOUT
    end
  end
end
