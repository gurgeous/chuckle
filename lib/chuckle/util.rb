require "digest/md5"
require "tempfile"

module Chuckle
  module Util
    extend self

    def rm_if_necessary(path)
      File.unlink(path) if File.exists?(path)
    end

    def md5(s)
      Digest::MD5.hexdigest(s.to_s)
    end

    def tmp_path
      Tempfile.open("chuckle") do |f|
        path = f.path
        f.unlink
        path
      end
    end
  end
end
