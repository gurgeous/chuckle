require "helper"

class TestRequests < Minitest::Test
  include Helper

  def test_200
    response = mcurl(HTTP_200) { client.get(URL) }
    assert_equal 200, response.code
    assert_equal URI.parse(URL), response.uri
    assert_equal "hello\n", response.body
  end

  def test_302
    response = mcurl(HTTP_302) { client.get(URL) }
    assert_equal 200, response.code
    assert_equal URI.parse("http://one"), response.uri
    assert_equal "hello\n", response.body
  end

  def test_302_2
    response = mcurl(HTTP_302_2) { client.get(URL) }
    assert_equal 200, response.code
    assert_equal URI.parse("http://two"), response.uri
    assert_equal "hello\n", response.body
  end

  def test_302_relative
    response = mcurl(HTTP_302_RELATIVE) { client.get(URL) }
    assert_equal 200, response.code
    assert_equal URI.parse("#{URL}/two"), response.uri
    assert_equal "hello\n", response.body
  end

  def test_404
    e = assert_raises Chuckle::Error do
      mcurl(HTTP_404) do
        client.get(URL)
      end
    end
    assert_equal 404, e.response.code
  end

  def test_timeout
    e = assert_raises Chuckle::Error do
      mcurl(HTTP_404, Chuckle::Error::CURL_TIMEOUT) do
        client.get(URL)
      end
    end
    assert e.timeout?, "exception didn't indicate timeout"
  end

  def test_post
    # just test hash_to_query first
    assert_equal "a=34&b=12&x+y=56", Chuckle::Util.hash_to_query(QUERY)

    response = mcurl(HTTP_200) { client.post(URL, QUERY) }
    assert_equal response.request.body, Chuckle::Util.hash_to_query(QUERY)
    assert_equal 200, response.code
    assert_equal URI.parse(URL), response.uri
    assert_equal "hello\n", response.body
  end
end
