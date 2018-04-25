require 'English'
require 'fileutils'

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

    def run
      # note: explicitly use Kernel.system to allow for mocking
      command = command(@request)
      Kernel.system(*command)

      # capture exit code, bail on INT
      exit_code = $CHILD_STATUS.to_i / 256
      if $CHILD_STATUS.termsig == Signal.list['INT']
        Process.kill(:INT, $PROCESS_ID)
      end

      # create tmp files if there were errors
      if !File.exist?(body_path)
        FileUtils.touch(body_path)
      end
      if exit_code != 0
        IO.write(headers_path, Curl.exit_code_to_headers(exit_code))
      end
    end

    # make sure we don't accidentally leave any files hanging around
    def cleanup
      Util.rm_if_necessary(headers_path)
      Util.rm_if_necessary(body_path)
    end

    def self.exit_code_to_headers(exit_code)
      "exit_code #{exit_code}"
    end

    def self.exit_code_from_headers(headers)
      if exit_code = headers[/^exit_code (\d+)/, 1]
        exit_code.to_i
      end
    end

    protected

    # the command line for this request, based on the request and the
    # options from client
    def command(request)
      client = request.client

      command = [ 'curl' ]
      command << '--silent'
      command << '--compressed'

      command += [ '--user-agent', client.user_agent ]
      command += [ '--max-time', client.timeout ]
      command += [ '--retry', client.nretries ]
      command += [ '--location', '--max-redirs', 3 ]

      if request.body
        command += [ '--data-binary', request.body ]
      end

      # maintain backwards compatibility for content type
      client.headers.each do |key, value|
        if key == 'Content-Type'
          command += [ '--header', "#{key}: #{value}" ] if request.body
        else
          command += [ '--header', "#{key}: #{value}" ]
        end
      end

      if client.cookies?
        cookie_jar.preflight
        command += [ '--cookie', cookie_jar.path ]
        command += [ '--cookie-jar', cookie_jar.path ]
      end

      # SSL options
      command += [ '--cacert', client.cacert ] if client.cacert
      command += [ '--capath', client.capath ] if client.capath
      command += [ '--insecure' ] if client.insecure?

      command += [ '--dump-header', headers_path ]
      command += [ '--output', body_path ]

      command << request.uri

      command = command.map(&:to_s)
      command
    end

    def cookie_jar
      @cookie_jar ||= CookieJar.new(@request)
    end
  end
end
