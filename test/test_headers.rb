require "helper"

# these actually use the network, and get skipped unless ENV["NETWORK"].
class TestHeaders < Minitest::Test
  include Helper

  def test_default_headers
    test_client = client(verbose: true)
    assert_equal({"Content-Type"=>"application/x-www-form-urlencoded"}, test_client.headers)
  end

  def test_content_type
    test_client = client(content_type: "text/json")
    assert_equal({"Content-Type"=>"text/json"}, test_client.headers)
  end

  def test_arbitrary_headers
    test_client = client(headers: {"Referer" => "http://foo.com"})
    assert_equal test_client.headers["Referer"], "http://foo.com"
    assert_equal test_client.headers["Content-Type"], "application/x-www-form-urlencoded"

  end

  def test_basic_get
    test_client = client(verbose: true)
    request = test_client.create_request("http://httpbin.org/get")
    headers = command_headers(request)
    assert_equal headers, []
  end


  def test_basic_post
    request = client(verbose: true).create_request("http://httpbin.org/post", "foo")
    headers = command_headers(request)
    assert_equal headers, ["Content-Type: application/x-www-form-urlencoded"]
  end

  def test_get_headers
    request = client(headers: {"Referer" => "http://foo.com"}).create_request("http://httpbin.org/get")
    headers = command_headers(request)
    assert_equal headers, ["Referer: http://foo.com"]
  end

  def test_post_headers
    request = client(headers: {"Referer" => "http://foo.com"}).create_request("http://httpbin.org/post", "foo")
    headers = command_headers(request)
    assert_equal headers.sort, ["Content-Type: application/x-www-form-urlencoded", "Referer: http://foo.com"]
  end

  private

  def command(request)
    curler = CurlStub.new(request)
    curler.test_command
  end

  def command_headers(request)
    headers = []
    test_command = command(request)
    test_command.each_with_index do |item, i|
      if item == "--header"
        headers << test_command[i+1]
      end
    end
    headers
  end

  class CurlStub < Chuckle::Curl
    def test_command
      command(@request)
    end
  end

end