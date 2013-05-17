module Chuckle
  module Caching
    # is this uri cached?
    def cached?(uri)
      File.exist?(cache_path(uri))
    end

    # rm the cached file for this uri
    def uncache!(uri)
      Util.rm_if_necessary(cache_path(uri))
    end

    # turn uri into a cache path
    def cache_path(uri, body = nil)
      uri = to_uri(uri)

      s = cache_dir
      s = "#{s}/#{pathify(uri.host)}"
      s = "#{s}/#{pathify(uri.path)}"
      if uri.query
        q = "?#{uri.query}"
        s = "#{s}#{pathify(q)}"
      end
      s = "#{s},#{pathify(body)}" if body

      # shorten long paths to md5 checksum
      if s.length > 250
        dir, base = File.dirname(s), File.basename(s)
        s = "#{dir}/#{Util.md5(base)}"
      end

      s
    end

    protected

    def stale?(path)
      return false if expires_in == :infinite || !File.exists?(path)
      File.stat(path).ctime + (expires_in * 24 * 60 * 60) < Time.now
    end

    # turn s into a string that can be a path
    def pathify(s)
      s = s.gsub(/^\//, "")
      s = s.gsub("..", ",")
      s = s.gsub(/[?\/&]/, ",")
      s = s.gsub(/[^A-Za-z0-9_.,=%-]/) do |i|
        hex = i.unpack("H2").first
        "%#{hex}"
      end
      s = s.downcase
      s = "_root_" if s.empty?
      s
    end
  end
end
