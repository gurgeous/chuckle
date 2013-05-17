require "helper"

# these actually use the network, and get skipped unless ENV["NETWORK"].
class TestNetwork < Minitest::Test
  include Helper

  def after_setup
    skip if !ENV["NETWORK"]
  end

  def test_get
    response = client.get("http://httpbin.org/get")
    assert_equal 200, response.code
  end

  def test_timeout
    e = assert_raises Chuckle::Error do
      client(nretries: 0, timeout: 2).get("http://httpbin.org/delay/3")
    end
    assert e.timeout?, "exception didn't indicate timeout"
  end
end
