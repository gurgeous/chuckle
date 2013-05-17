# Welcome to chuckle

Chuckle is an http client with a disk-based cache. HTTP responses are cached on disk in a way that makes them easy to find and debug. The cache can be shared between machines. Features:

* Disk caching, with expiration
* Cookies (also cached)
* Robust support for timeouts and retries (also cached)

This gem is an extraction from [Dwellable](http://dwellable.com). We use it for tasks such as:

* Crawling content from partner web sites, including sites that require cookies
* Downloading photo sets from partner web sites
* Broken link detection
* Wrapping slow or rate-limited APIs with caching
* Sharing cached http responses between developers or machines

## Install

```ruby
gem install chuckle
```

## Example Usage

```ruby
require "chuckle"

client = Chuckle::Client.new

# This makes a network request. The response will be cached in
# ~/.chuckle/www.google.com/_root_
#
# => Chuckle::Response http://www.google.com code=200
p client.get("http://www.google.com")

# Since the response is now cached, no network is required here.
#
# => Chuckle::Response http://www.google.com code=200
p client.get("http://www.google.com")
```

## Options

Not documented yet - see `Chuckle::Options`.

## Limitations

* Only supports GET and POST.
* Cookies aren't intended to be cached, but we do it anyway. This works fine for our use case, where we crawl a site all at once and then clear the cache before re-crawling. Also, cookies are cached on a per-host basis so subdomains and wildcard cookies will be a problem. Use caution!
* The cache naming scheme isn't perfect. It's theoretically possible for two URLs to map to the same cache filename, though we haven't seen this happen in the wild.
* Chuckle shells out to [curl](http://curl.haxx.se/) for each request. Curl is rock solid and has great support for cookies, timeouts, compression, retries, etc. That makes Chuckle slower than other http clients, though network speed and rate limiting dwarf all such considerations.
