module Chuckle
  class Cache
    def initialize(client)
      @client = client
    end

    def get(request)
      if !exists?(request)
        return nil
      end
      if stale?(request)
        clear(request)
        return nil
      end
      Response.new(request)
    end

    def set(request, curl)
      %w(body headers).each do |i|
        src, dst = curl.send("#{i}_path"), request.send("#{i}_path")
        FileUtils.mkdir_p(File.dirname(dst))
        FileUtils.mv(src, dst)
      end
      Response.new(request)
    end

    def clear(request)
      Util.rm_if_necessary(request.headers_path)
      Util.rm_if_necessary(request.body_path)
    end

    def exists?(request)
      File.exists?(request.body_path)
    end

    def stale?(request)
      return false if @client.expires_in == :never
      return false if !exists?(request)
      File.stat(request.body_path).mtime + @client.expires_in < Time.now
    end

    def body_path(request)
      uri = request.uri

      # calculate body_path
      s = @client.cache_dir
      s = "#{s}/#{pathify(uri.host)}"
      s = "#{s}/#{pathify(uri.path)}"
      if uri.query
        q = "?#{uri.query}"
        body_path = "#{s}#{pathify(q)}"
      end
      if body = request.body
        body_path = "#{s},#{pathify(body)}"
      end

      # shorten long paths to md5 checksum
      if s.length > 250
        dir, base = File.dirname(s), File.basename(s)
        s = "#{dir}/#{Util.md5(base)}"
      end

      s
    end

    protected

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
