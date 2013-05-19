require "awesome_print"
require "chuckle"
require "json"
require "minitest/autorun"
require "minitest/pride"

module Helper
  CACHE_DIR = "/tmp/_chuckle_tests"
  URL = "http://chuckle"
  QUERY = { "b" => "12", "a" => "34", "x y" => "56" }

  #
  # fake responses
  #

  HTTP_200 = <<-EOF.gsub(/(^|\n) +/, "\\1")
    HTTP/1.1 200 OK

    hello
  EOF

  HTTP_200_ALTERNATE = <<-EOF.gsub(/(^|\n) +/, "\\1")
    HTTP/1.1 200 OK

    alternate
  EOF

  HTTP_302 = <<-EOF.gsub(/(^|\n) +/, "\\1")
    HTTP/1.1 302 FOUND
    Location: http://one

    HTTP/1.0 200 OK

    hello
  EOF

  HTTP_302_2 = <<-EOF.gsub(/(^|\n) +/, "\\1")
    HTTP/1.1 302 FOUND
    Location: http://one

    HTTP/1.1 302 FOUND
    Location: http://two

    HTTP/1.0 200 OK

    hello
  EOF

  HTTP_302_RELATIVE = <<-EOF.gsub(/(^|\n) +/, "\\1")
    HTTP/1.1 302 FOUND
    Location: /two

    HTTP/1.0 200 OK

    hello
  EOF

  HTTP_404 = <<-EOF.gsub(/(^|\n) +/, "\\1")
    HTTP/1.1 404 Not Found

  EOF

  def setup
    # clear the cache before each test
    FileUtils.rm_rf(CACHE_DIR)
  end

  # create a new client, with options
  def client(options = {})
    @client ||= begin
      options = options.merge(cache_dir: CACHE_DIR)
      Chuckle::Client.new(options)
    end
  end

  # pretend to be curl by stubbing Kernel.system
  def mcurl(response, exit_code = 0, &block)
    # divide response into headers/body
    sep = response.rindex("\n\n") + "\n\n".length
    body = response[sep..-1]
    headers = response[0, sep].gsub("\n", "\r\n")

    # a lambda that pretends to be curl
    fake_system = lambda do |*command|
      tmp_headers = command[command.index("--dump-header") + 1]
      tmp_body    = command[command.index("--output") + 1]
      IO.write(tmp_headers, headers)
      IO.write(tmp_body, body)
      `(exit #{exit_code})`
    end

    # stub out Kernel.system
    Kernel.stub(:system, fake_system) { yield }
  end

  def assert_if_system(&block)
    fake_system = lambda do |*command|
      assert false, "system called with #{command.inspect}"
    end
    Kernel.stub(:system, fake_system) { yield }
  end
end
