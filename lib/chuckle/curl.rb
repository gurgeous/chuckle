require "fileutils"
require "ostruct"

module Chuckle
  class Curl
    def initialize(chuckle, request)
      @chuckle = chuckle
      @request = request
    end

    def tmp_body
      @tmp_body ||= Util.tmp_path
    end

    def tmp_headers
      @tmp_headers ||= Util.tmp_path
    end

    # build the curl command line arguments
    def command(request)
      command = ["curl"]
      command << "--silent"
      command += [ "--user-agent", @chuckle.user_agent]
      command += ["--max-time", @chuckle.timeout]
      command += ["--retry", @chuckle.nretries]
      command += ["--location", "--max-redirs", 3]
      if request.body
        command += ["--data-binary", request.body]
        command += ["--header", "Content-Type: application/x-www-form-urlencoded"]
      end
      if @chuckle.cookie_jar
        command += ["--cookie", @chuckle.cookie_jar]     # Read cookies from file
        command += ["--cookie-jar", @chuckle.cookie_jar] # Write cookies to file
      end
      command += ["--dump-header", tmp_headers]
      command += ["--output", tmp_body]
      command << request.uri

      command = command.map(&:to_s)
      command
    end

    def run
      command = command(@request)
      # explicitly use Kernel to allow for mocking
      Kernel.system(*command)

      # capture exit code, bail on INT
      exit_code = $?.to_i / 256
      if exit_code != 0
        if $?.termsig == Signal.list["INT"]
          Process.kill(:INT, $$)
        end
      end

      #
      # fix tmp files if there were errors
      #

      if exit_code != 0
        IO.write(tmp_body, "")
        IO.write(tmp_headers, "exit_code #{exit_code}")
      elsif !File.exists?(tmp_body)
        FileUtils.touch(tmp_body)
      end
    end
  end
end
