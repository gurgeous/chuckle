module Chuckle
  class Request
    attr_accessor :chuckle, :uri, :body

    def initialize(chuckle, uri, body = nil)
      self.chuckle = chuckle
      self.uri = uri
      self.body = body
    end

    def headers
      @headers ||= begin
        dir, base = File.dirname(cache), File.basename(cache)
        "#{dir}/head/#{base}"
      end
    end

    def cache
      chuckle.cache_path(uri, body)
    end

    def inspect #:nodoc:
      s = "#{self.class} #{uri}"
      if body
        s = "#{s} (#{body.length} bytes)"
      end
      s
    end
  end
end
