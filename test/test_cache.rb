require "helper"

class TestCache < Minitest::Test
  include Helper

  # cached? and uncache!
  def test_predicates
    client(expires_in: 10) # set options

    request = client.create_request(URL)
    assert !client.cache.exists?(request), "uncache! uri said it was cached"

    with_mock_curl(HTTP_200) do
      client.run(request)
    end
    assert client.cache.exists?(request), "cache said it wasn't cached"
    assert !client.cache.stale?(request), "cache said it was stale"

    client.cache.clear(request)
    assert !client.cache.exists?(request), "uncache! said it was cached"
  end

  # cache expiration
  def test_expiry
    client(expires_in: 10) # set options

    request = client.create_request(URL)
    response = with_mock_curl(HTTP_200) do
      client.run(request)
    end
    assert_equal "hello\n", response.body

    # make it look old
    tm = Time.now - (client.expires_in + 60)
    path = request.body_path
    File.utime(tm, tm, path)
    assert client.cache.stale?(request), "#{path} was supposed to be stale"

    # make sure we get the new body
    response = with_mock_curl(HTTP_200_ALTERNATE) do
      client.run(request)
    end
    assert_equal "alternate\n", response.body
  end

  #
  # requests and errors
  #

  def test_200
    # cache miss
    with_mock_curl(HTTP_200) do
      client.get(URL)
    end

    # cache hit
    response = assert_if_system do
      client.get(URL)
    end
    assert_equal 200, response.code
    assert_equal URI.parse(URL), response.uri
    assert_equal "hello\n", response.body
  end

  def test_404
    # cache miss
    begin
      with_mock_curl(HTTP_404) do
        client.get(URL)
      end
    rescue Chuckle::Error => e
    end

    # cache hit
    e = assert_raises Chuckle::Error do
      assert_if_system do
        client.get(URL)
      end
    end
    assert_equal 404, e.response.code
  end

  def test_timeout
    # cache miss
    begin
      with_mock_curl(HTTP_404, Chuckle::Error::CURL_TIMEOUT) do
        client.get(URL)
      end
    rescue Chuckle::Error => e
    end

    # cache hit
    e = assert_raises Chuckle::Error do
      assert_if_system do
        client.get(URL)
      end
    end
    assert e.timeout?, "exception didn't indicate timeout"
  end
end
