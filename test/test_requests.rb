require "helper"

#
# these are mock tests, so they don't really run curl
#

class TestRequests < Minitest::Test
  include Helper

  def test_200
    response = with_mock_curl(HTTP_200) { client.get(URL) }
    assert_equal 200, response.code
    assert_equal URI.parse(URL), response.uri
    assert_equal "hello\n", response.body
  end

  def test_302
    response = with_mock_curl(HTTP_302) { client.get(URL) }
    assert_equal 200, response.code
    assert_equal URI.parse("http://one"), response.uri
    assert_equal "hello\n", response.body
  end

  def test_302_2
    response = with_mock_curl(HTTP_302_2) { client.get(URL) }
    assert_equal 200, response.code
    assert_equal URI.parse("http://two"), response.uri
    assert_equal "hello\n", response.body
  end

  def test_404
    e = assert_raises Chuckle::Error do
      with_mock_curl(HTTP_404) do
        client.get(URL)
      end
    end
    assert_equal 404, e.response.code
  end

  def test_timeout
    e = assert_raises Chuckle::Error do
      with_mock_curl(HTTP_404, Chuckle::Error::CURL_TIMEOUT) do
        client.get(URL)
      end
    end
    assert e.timeout?, "exception didn't indicate timeout"
  end
end
