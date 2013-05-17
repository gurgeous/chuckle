require "fileutils"
require "ostruct"

module Chuckle
  class Curl
    def initialize(request)
      @request = request
    end

    # tmp path for response headers
    def headers_path
      @headers_path ||= Util.tmp_path
    end

    # tmp path for response body
    def body_path
      @body_path ||= Util.tmp_path
    end

    # the command line for this request, based on the request and the
    # options from client
    def command(request)
      client = request.client
      command = ["curl"]
      command << "--silent"
      command << "--compressed"
      command += [ "--user-agent", client.user_agent]
      command += ["--max-time", client.timeout]
      command += ["--retry", client.nretries]
      command += ["--location", "--max-redirs", 3]
      if request.body
        command += ["--data-binary", request.body]
        command += ["--header", "Content-Type: application/x-www-form-urlencoded"]
      end
      if client.cookie_jar
        FileUtils.mkdir_p(File.dirname(cookie_jar))
        command += ["--cookie", client.cookie_jar]     # Read cookies from file
        command += ["--cookie-jar", client.cookie_jar] # Write cookies to file
      end
      command += ["--dump-header", headers_path]
      command += ["--output", body_path]
      command << request.uri

      command = command.map(&:to_s)
      command
    end

    def run
      # note: explicitly use Kernel.system to allow for mocking
      command = command(@request)
      Kernel.system(*command)

      # capture exit code, bail on INT
      exit_code = $?.to_i / 256
      if exit_code != 0 && $?.termsig == Signal.list["INT"]
        Process.kill(:INT, $$)
      end

      # create tmp files if there were errors
      if !File.exists?(body_path)
        FileUtils.touch(body_path)
      end
      if exit_code != 0
        IO.write(headers_path, Curl.exit_code_to_headers(exit_code))
      end
    end

    def self.exit_code_to_headers(exit_code)
      "exit_code #{exit_code}"
    end

    def self.exit_code_from_headers(headers)
      if exit_code = headers[/^exit_code (\d+)/, 1]
        exit_code.to_i
      end
    end
  end
end
