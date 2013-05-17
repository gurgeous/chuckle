module Chuckle
  class CookieJar
    PATH = "/_chuckle_cookies.txt"

    def initialize(request)
      @request = request
    end

    def bogus_request
      @bogus_request ||= Request.new(@request.client, @request.uri + PATH)
    end

    def path
      bogus_request.body_path
    end

    def preflight
      # expire the cookie jar if necessary
      bogus_request.client.cache.expired?(bogus_request)
      # mkdir
      FileUtils.mkdir_p(File.dirname(path))
    end
  end
end
