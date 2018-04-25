module Chuckle
  class Response
    attr_accessor :request, :curl_exit_code, :uri, :code

    def initialize(request)
      self.request = request
      self.uri = request.uri
      parse
    end

    def headers
      @headers ||= File.read(request.headers_path)
    end

    def body
      @body ||= File.read(request.body_path)
    end

    def to_s #:nodoc:
      inspect
    end

    def inspect #:nodoc:
      "#{self.class} #{uri} code=#{code}"
    end

    protected

    def parse
      self.curl_exit_code = Curl.exit_code_from_headers(headers)

      self.uri = request.uri
      locations = headers.scan(/^Location: ([^\r\n]+)/m).flatten
      if !locations.empty?
        location = locations.last
        # some buggy servers do this. sigh.
        location = location.gsub(' ', '%20')
        self.uri += location
      end

      codes = headers.scan(/^HTTP\/\d(?:\.\d)? (\d+).*?\r\n/m).flatten
      codes = codes.map(&:to_i)
      self.code = codes.last
    end
  end
end
