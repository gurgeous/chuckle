module Chuckle
  module Cookies
    def setup_cookies
      if cookie_jar
        vputs "using cookie jar #{cookie_jar}."

        # Apply expires_in to cookie_jar too. Don't want the cookies
        # and cache to get out of sync.
        if stale?(cookie_jar)
          File.unlink(cookie_jar)
        end
      end
    end
  end
end
