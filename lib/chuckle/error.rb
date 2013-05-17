module Chuckle
  class Error < StandardError
    attr_accessor :request, :curl_exit_code, :response

    def timeout?
      curl_exit_code == 28
    end
  end
end
