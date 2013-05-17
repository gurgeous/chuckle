module Chuckle
  class Request
    attr_accessor :client, :uri, :body

    def initialize(client, uri, body = nil)
      self.client = client
      self.uri = uri
      self.body = body
    end

    def headers_path
      @headers_path ||= begin
        dir, base = File.dirname(body_path), File.basename(body_path)
        "#{dir}/head/#{base}"
      end
    end

    def body_path
      @body_path ||= client.cache.body_path(self)
    end

    def to_s #:nodoc:
      inspect
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
