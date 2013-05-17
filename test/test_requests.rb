require "helper"

#
# these are mock tests, so they don't really run curl
#

class TestRequests < Minitest::Test
  include Helper

  def test_200
    response = with_mock_curl(<<EOF) do
HTTP/1.1 200 OK

gub
EOF
      chuckle.get("http://mock")
    end
    assert_equal 200, response.code
    assert_equal URI.parse("http://mock"), response.uri
    assert_equal "gub\n", response.body
  end

  def test_30x
    response = with_mock_curl(<<EOF) do
HTTP/1.1 302 FOUND
Location: http://one

HTTP/1.0 200 OK

gub
EOF
      chuckle.get("http://mock")
    end
    assert_equal 200, response.code
    assert_equal URI.parse("http://one"), response.uri
    assert_equal "gub\n", response.body
  end

  def test_30x_twice
    response = with_mock_curl(<<EOF) do
HTTP/1.1 302 FOUND
Location: http://one

HTTP/1.1 302 FOUND
Location: http://two

HTTP/1.0 200 OK

gub
EOF
      chuckle.get("http://mock")
    end
    assert_equal 200, response.code
    assert_equal URI.parse("http://two"), response.uri
    assert_equal "gub\n", response.body
  end

  def test_404
    e = assert_raises Chuckle::Error do
      with_mock_curl(<<EOF) do
HTTP/1.1 404 Not Found

EOF
        chuckle.get("http://mock")
      end
    end
    assert_equal 404, e.response.code
  end

  def test_timeout
    e = assert_raises Chuckle::Error do
      with_mock_curl(<<EOF, Chuckle::Error::CURL_TIMEOUT) do
HTTP/1.1 404 Not Found

EOF
        chuckle.get("http://mock")
      end
    end
    assert e.timeout?, "exception didn't indicate timeout"
  end
end
