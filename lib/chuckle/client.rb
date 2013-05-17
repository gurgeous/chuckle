require "fileutils"

module Chuckle
  class Client
    include Chuckle::Options

    attr_accessor :options, :cache

    def initialize(options = {})
      self.options = options
      self.cache = Cache.new(self)
    end

    #
    # main entry points
    #

    def create_request(uri, body = nil)
      Request.new(self, to_uri(uri), body)
    end

    def get(uri)
      run(create_request(uri))
    end

    def post(uri, body)
      run(create_request(uri, body))
    end

    def run(request)
      response = cache.get(request) || curl(request)
      raise_errors(response)
      response
    end

    def inspect #:nodoc:
      self.class.name
    end

    protected

    def curl(request)
      vputs request.uri
      rate_limit!(request)
      curl = Curl.new(request)
      curl.run
      cache.set(request, curl)
    end

    def raise_errors(response)
      # raise errors if necessary
      if response.curl_exit_code
        e = Error.new("Chuckle::Error, curl exit code #{response.curl_exit_code}")
        e.response = response
        raise e
      end
      if response.code >= 400
        e = Error.new("Chuckle::Error, http status #{response.code}")
        e.response = response
        raise e
      end
    end

    def vputs(s)
      puts "chuckle: #{s}" if verbose?
    end

    # convert s into a URI if necessary
    def to_uri(s)
      if !s.is_a?(URI)
        s = URI.parse(s.to_s)
      end
      s
    end

    def rate_limit!(request)
      return if !request.uri.host
      @last_request ||= Time.at(0)
      sleep = (@last_request + rate_limit) - Time.now
      sleep(sleep) if sleep > 0
      @last_request = Time.now
    end
  end
end
