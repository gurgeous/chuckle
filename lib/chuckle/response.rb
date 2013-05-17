module Chuckle
  class Response
    attr_accessor :chuckle, :request, :uri, :code

    def initialize(chuckle, request)
      self.chuckle = chuckle
      self.request = request
    end

    def body
      @body ||= File.read(request.cache)
    end

    def inspect #:nodoc:
      "#{self.class} #{uri} code=#{code}"
    end
  end
end
