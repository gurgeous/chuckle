module Chuckle
  module Options
    IE9 = "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0"

    def verbose?
      options[:verbose]
    end

    # number of seconds between requests
    def rate_limit
      @rate_limit ||= options[:rate_limit] || 1
    end

    # number of days to cache responses and cookies, or :infinite
    def expires_in
      @expires_in ||= options[:expires_in] || :infinite
    end

    # number of retries to attempt
    def nretries
      @nretries ||= options[:nretries] || 3
    end

    # timeout per retry
    def timeout
      @timeout ||= options[:timeout] || 30
    end

    # user agent
    def user_agent
      @user_agent ||= options[:user_agent] || IE9
    end

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

    # cookie jar file
    def cookie_jar
      if !defined?(@cookie_jar)
        if dir = options[:cookie_jar]
          # Handle relative or absolute paths.  Relative paths are
          # interpreted to be relative to the @root.
          dir = File.expand_path(dir, cache_dir)
        end
        @cookie_jar = dir
      end
      @cookie_jar
    end
  end
end
