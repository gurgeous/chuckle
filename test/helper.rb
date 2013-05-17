require "awesome_print"
require "chuckle"
require "minitest/autorun"
require "minitest/pride"

module Helper
  CACHE_DIR = "/tmp/_chuckle_tests"

  def setup
    FileUtils.rm_rf(CACHE_DIR)
  end

  def chuckle(options = {})
    options = options.merge(cache_dir: CACHE_DIR)
    Chuckle::Client.new(options)
  end

  # pretend to be curl by stubbing Kernel.system
  def with_mock_curl(response, exit_code = 0, &block)
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
end
