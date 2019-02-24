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

Pass these `Chuckle::Client.new`:

* **cache_dir** (~/.chuckle) - where chuckle should cache files. If HOME doesn't exist or isn't writable, it'll use `/tmp/chuckle` instead
* **cache_errors** (true) - false to not cache errors on disk (timeouts, http status >= 400, etc.)
* **cacert** (nil) - cacert option to pass to curl
* **capath** (nil) - capath option to pass to curl
* **cookies** (false) - true to turn on cookie support
* **content_type** (application/x-www-form-urlencoded) - default content type for POST
* **expires_in** (:never) - time in seconds after which cache files should expire, or `:never` to never expire
* **insecure** (false) - true to allow insecure SSL connections
* **headers** (nil) - optional hash of headers to include for all requests.  Content-Type is overwritten by the :content_type option.  example: {"Referer" => "http://foo.com"}
* **nretries** (2) - number of times to retry a failing request
* **rate_limit** (1) - number of seconds between requests
* **timeout** (30) - timeout per request. Note that if `nretries` is 2 and `timeout` is 30, a failing request could take 90 seconds to truly fail.
* **user_agent** - the user agent. Defaults to the IE9 user agent.
* **verbose** (false) - if true, prints each request before fetching. Only prints network requests.

## Changelog

* 1.0.9 (Feb 2019_ - switch trollop to optimist. Perhaps we'll make it all the way to slop someday! (@jamezilla)
* 1.0.8 - we mourn this lost version
* 1.0.7 (Apr 2018) - HTTP2 fix and more rubies (@nkriege)
* 1.0.6 (May 2015) - added support for setting arbitrary headers (@pattymac)
* 1.0.5 (Jan 2015) - added support for setting content type (@pattymac)
* 1.0.4 (Dec 2014) - added support for --cacert, --capath and --insecure (@nkriege)


## Limitations

* Only supports GET and POST.
* Cookies aren't intended to be cached, but we do it anyway. This works fine for our use case, where we crawl a site all at once and then clear the cache before re-crawling. Also, cookies are cached on a per-host basis so subdomains and wildcard cookies will be a problem. Use caution!
* The cache naming scheme isn't perfect. It's theoretically possible for two URLs to map to the same cache filename, though we haven't seen this happen in the wild.
* Chuckle shells out to [curl](http://curl.haxx.se/) for each request. Curl is rock solid and has great support for cookies, timeouts, compression, retries, etc. That makes Chuckle slower than other http clients, though network speed and rate limiting dwarf all such considerations.
