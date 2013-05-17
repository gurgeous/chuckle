require "fileutils"

module Chuckle
  class Client
    include Chuckle::Caching
    include Chuckle::Options

    attr_accessor :options

    def initialize(options = {})
      @options = options
    end

    #
    # main entry points
    #

    def get(uri)
      run(Request.new(self, to_uri(uri)))
    end

    def post(uri, body)
      run(Request.new(self, to_uri(uri), body))
    end

    def inspect #:nodoc:
      self.class.name
    end

    protected

    def run(request)
      rm_if_stale(request)
      curl(request) if !File.exists?(request.cache)
      parse(request)
    end

    # remove cached request if stale
    def rm_if_stale(request)
      if stale?(request.cache)
        Util.rm_if_necessary(request.cache)
        Util.rm_if_necessary(request.headers)
      end
    end

    def curl(request)
      vputs request.uri
      rate_limit!(request)

      # mkdirs
      dirs = [ request.cache, request.headers, cookie_jar ].compact.map { |i| File.dirname(i) }
      FileUtils.mkdir_p(dirs)

      # curl!
      curl = Curl.new(self, request)
      curl.run

      #
      # now atomically mv tmp files into cache
      #

      FileUtils.mv(curl.tmp_body, request.cache)
      FileUtils.mv(curl.tmp_headers, request.headers)
    end

    # read cache and create response
    def parse(request)
      response = Response.new(self, request)
      response.uri = request.uri

      # headers
      headers = IO.read(request.headers)

      # exit_code?
      if exit_code = headers[/^exit_code (\d+)/, 1]
        e = Error.new("chuckle failed, curl exit_code=#{exit_code}")
        e.request = request
        e.exit_code = exit_code
        raise e
      end

      # get the final response
      headers = headers.scan(/^HTTP\/\d\.\d \d+.*?\r\n\r\n/m).last
      response.code = headers[/^HTTP\/\d\.\d (\d+)/, 1].to_i
      if location = headers[/^Location: ([^\r\n]+)/, 1]
        # some buggy servers do this. sigh.
        location = location.gsub(" ", "%20")
        response.uri = URI.parse(location)
      end

      if response.code >= 400
        e = Error.new("chuckle failed, http status=#{response.code}")
        e.request = request
        e.response = response
        raise e
      end

      response
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
