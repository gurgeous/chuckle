require "uri"

module Chuckle
  class Client
    include Chuckle::Options

    attr_accessor :options, :cache

    def initialize(options = {})
      self.options = DEFAULT_OPTIONS.dup
      options.each { |k, v| self.options[k] = v if v != nil }
      self.cache = Cache.new(self)
      sanity!
    end

    #
    # main entry points
    #

    def create_request(uri, body = nil)
      uri = URI.parse(uri.to_s) if !uri.is_a?(URI)
      Request.new(self, uri, body)
    end

    def get(uri)
      run(create_request(uri))
    end

    def post(uri, body)
      body = case body
      when Hash
        Util.hash_to_query(body)
      else
        body.to_s
      end
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

    # make sure curl command exists
    def sanity!
      system("which curl > /dev/null")
      raise "Chuckle requires curl. Please install it." if $? != 0
    end

    def curl(request)
      vputs request.uri
      rate_limit!(request)

      curl = Curl.new(request)
      begin
        curl.run
        cache.set(request, curl)
      ensure
        curl.cleanup
      end
    end

    def raise_errors(response)
      # raise errors if necessary
      error = if response.curl_exit_code
        "curl exit code #{response.curl_exit_code}"
      elsif response.code >= 400
        "http status #{response.code}"
      end
      return if !error

      if !cache_errors?
        cache.clear(response.request)
      end
      raise Error.new(error, response)
    end

    def vputs(s)
      puts "chuckle: #{s}" if verbose?
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
