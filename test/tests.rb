require "awesome_print"
require "chuckle"
require "minitest/autorun"
require "minitest/mock"

class Tests < Minitest::Test
  CACHE_DIR = "/tmp/_chuckle_tests"

  def setup
    FileUtils.rm_rf(CACHE_DIR)
  end

  def chuckle(options = {})
    options = options.merge(cache_dir: CACHE_DIR)
    Chuckle::Client.new(options)
  end

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

  def test_200
    response = with_mock_curl("HTTP/1.1 200 OK\n\ngub") do
      chuckle.get("http://mock")
    end
    assert_equal response.body, "gub"
  end

  def test_404
    e = assert_raises Chuckle::Error do
      with_mock_curl("HTTP/1.1 404 Not Found\n\ngub") do
        chuckle.get("http://mock")
      end
    end
    assert_equal e.response.code, 404
  end

  if ENV["SLOW"]
    # end-to-end: actually hit a server
    def test_google
      chuckle.get("http://google.com")
    end
  end

  protected

  def cache_dir
    "/tmp/_chuckle_tests"
  end
end

# things to test:
#
# end to end
#   response.url (200)
#   301 redirects
#   timeouts
#   nothing in the cache
#   something in the cache
# walk every method and see if it can easily be tested!
#   cache_dir

# REMIND: bin
