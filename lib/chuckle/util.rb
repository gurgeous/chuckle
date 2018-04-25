require 'digest/md5'
require 'tempfile'

module Chuckle
  module Util
    module_function

    def hash_to_query(hash)
      q = hash.map do |key, value|
        key = CGI.escape(key.to_s)
        value = CGI.escape(value.to_s)
        "#{key}=#{value}"
      end
      q.sort.join('&')
    end

    def md5(s)
      Digest::MD5.hexdigest(s.to_s)
    end

    def rm_if_necessary(path)
      File.unlink(path) if File.exist?(path)
    end

    def tmp_path
      Tempfile.open('chuckle') do |f|
        path = f.path
        f.unlink
        path
      end
    end
  end
end
