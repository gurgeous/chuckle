module Chuckle
  module Options
    DEFAULT_OPTIONS = {
      cache_dir: nil,
      cache_errors: true,
      cacert: nil,
      capath: nil,
      content_type: "application/x-www-form-urlencoded",
      cookies: false,
      expires_in: :never,
      headers: nil,
      insecure: false,
      nretries: 2,
      rate_limit: 1,
      timeout: 30,
      user_agent: "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0",
      verbose: false,
    }

    # cache root directory
    def cache_dir
      @cache_dir ||= begin
        dir = options[:cache_dir]
        dir ||= begin
          if home = ENV["HOME"]
            if File.exists?(home) && File.stat(home).writable?
              "#{home}/.chuckle"
            end
          end
        end
        dir ||= "/tmp/chuckle"
        dir
      end
    end

    # should errors be cached?
    def cache_errors?
      options[:cache_errors]
    end

    # cacert to pass to curl
    def cacert
      options[:cacert]
    end

    # capath to pass to curl
    def capath
      options[:capath]
    end

    def content_type
      options[:content_type]
    end

    # are cookies enabled?
    def cookies?
      options[:cookies]
    end

    # number of seconds to cache responses and cookies, or :never
    def expires_in
      options[:expires_in]
    end

    # maintain backwards compatibility for content_type
    def headers
      @headers ||= begin
        headers = options[:headers] || {}
        headers["Content-Type"] = options[:content_type] if options[:content_type]
        headers
      end
    end

    # allow insecure SSL connections?
    def insecure?
      options[:insecure]
    end

    # number of retries to attempt
    def nretries
      options[:nretries]
    end

    # number of seconds between requests
    def rate_limit
      options[:rate_limit]
    end

    # timeout per retry
    def timeout
      options[:timeout]
    end

    # user agent
    def user_agent
      options[:user_agent]
    end

    # verbose output?
    def verbose?
      options[:verbose]
    end
  end
end
