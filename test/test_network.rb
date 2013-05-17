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

  def test_post
    response = client.post("http://httpbin.org/post", QUERY)
    assert_equal JSON.parse(response.body)["form"], QUERY
  end

  def test_cookies
    cookies = { "a" => "b" }

    client(cookies: true, expires_in: 60) # set options

    request = client.create_request("http://httpbin.org/get")
    cookie_jar = Chuckle::CookieJar.new(request).path

    # make sure there are no cookies after the GET
    client.run(request)
    assert !File.exists?(cookie_jar), "cookie jar shouldn't exist yet"

    # make sure there ARE cookies after a Set-Cookie
    client.get("http://httpbin.org/cookies/set?#{Chuckle::Util.hash_to_query(cookies)}")
    assert File.exists?(cookie_jar), "cookie jar SHOULD exist now"

    # make sure cookies come back from the server
    response = client.get("http://httpbin.org/cookies")
    assert_equal JSON.parse(response.body)["cookies"], cookies

    # Finally, test cache expiry on cookie_jar. Note that this has to
    # be an un-cached URL, otherwise the cookie_jar never gets
    # checked!
    tm = Time.now - (client.expires_in + 9999)
    File.utime(tm, tm, cookie_jar)
    client.get("http://httpbin.org/robots.txt")
    assert !File.exists?(cookie_jar), "cookie jar should've expired"
  end
end
