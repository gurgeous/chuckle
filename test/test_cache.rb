require "helper"

class TestCache < Minitest::Test
  include Helper

  def after_setup
    client(expires_in: 10)
  end

  # exists? and expired? (and clear)
  def test_predicates
    request = client.create_request(URL)
    assert !client.cache.exists?(request), "uncache! uri said it was cached"

    mcurl(HTTP_200) do
      client.run(request)
    end
    assert client.cache.exists?(request), "cache said it wasn't cached"
    assert !client.cache.expired?(request), "cache said it was expired"

    client.cache.clear(request)
    assert !client.cache.exists?(request), "still cached after clear"
  end

  # cache expiration
  def test_expiry
    request = client.create_request(URL)
    response = mcurl(HTTP_200) do
      client.run(request)
    end
    assert_equal "hello\n", response.body

    # make it look old
    tm = Time.now - (client.expires_in + 9999)
    path = request.body_path
    File.utime(tm, tm, path)
    assert client.cache.expired?(request), "#{path} was supposed to be expired"

    # make sure we get the new body
    response = mcurl(HTTP_200_ALTERNATE) do
      client.run(request)
    end
    assert_equal "alternate\n", response.body
    assert_equal 2, client.cache.misses
  end

  #
  # requests and errors
  #

  def test_200
    # cache miss
    mcurl(HTTP_200) do
      client.get(URL)
    end

    # cache hit
    response = assert_if_system do
      client.get(URL)
    end
    assert_equal 200, response.code
    assert_equal URI.parse(URL), response.uri
    assert_equal "hello\n", response.body
    assert_equal 1, client.cache.hits
    assert_equal 1, client.cache.misses
  end

  def test_404
    # cache miss
    begin
      mcurl(HTTP_404) do
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
    assert_equal 1, client.cache.hits
    assert_equal 1, client.cache.misses
  end

  def test_timeout
    # cache miss
    begin
      mcurl(HTTP_404, Chuckle::Error::CURL_TIMEOUT) do
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
    assert_equal 1, client.cache.hits
    assert_equal 1, client.cache.misses
  end

  def test_post
    # cache miss
    mcurl(HTTP_200) do
      client.post(URL, QUERY)
    end

    # cache hit
    response = assert_if_system do
      client.post(URL, QUERY)
    end
    assert_equal 200, response.code
    assert_equal URI.parse(URL), response.uri
    assert_equal "hello\n", response.body
    assert_equal 1, client.cache.hits
    assert_equal 1, client.cache.misses
  end

  def test_long_url
    words = %w(the quick brown fox jumped over the lazy dog)
    query = (1..100).map { words[rand(words.length)] }
    query = query.each_slice(2).map { |i| i.join("=") }.join("&")

    # cache miss
    mcurl(HTTP_200) do
      client.post(URL, query)
    end

    # cache hit
    response = assert_if_system do
      client.post(URL, query)
    end

    # make sure it turned into a checksum
    assert response.request.body_path =~ /[a-f0-9]{32}$/, "body_path wasn't an md5 checksum"
    assert_equal 200, response.code
    assert_equal URI.parse(URL), response.uri
    assert_equal "hello\n", response.body
    assert_equal 1, client.cache.hits
    assert_equal 1, client.cache.misses
  end

  def test_query
    url = "#{URL}?abc=def"

    # cache miss
    mcurl(HTTP_200) do
      client.get(url)
    end

    # cache hit
    response = assert_if_system do
      client.get(url)
    end

    # make sure it turned into a checksum
    assert response.request.body_path =~ /abc=def$/, "body_path didn't contain query"
    assert_equal 200, response.code
    assert_equal URI.parse(url), response.uri
    assert_equal "hello\n", response.body
    assert_equal 1, client.cache.hits
    assert_equal 1, client.cache.misses
  end

  def test_nocache_errors
    # turn off error caching
    client = Chuckle::Client.new(cache_dir: CACHE_DIR, expires_in: 10, cache_errors: false)

    # cache misses
    2.times do
      begin
        mcurl(HTTP_404) { client.get(URL) }
      rescue Chuckle::Error
      end
    end
    assert_equal 2, client.cache.misses
  end
end
