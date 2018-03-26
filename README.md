# Betamocks

Betamocks is Faraday middleware that mocks APIs by recording and replaying requests.
It's especially useful for local development to mock out APIs that are behind a VPN (government),
often go down (government), or when an API may not have a corresponding dev or staging environment (also government).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'betamocks'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install betamocks

## Usage

### Configuration

In a location that gets loaded before your Faraday connections are initialized (e.g. a Rails initializer)
configure the Betamocks `enabled`, `cache_dir`, and `services_config` settings:

- __enabled__: globally turn Betamocks on `true` or off `false`
- __cache_dir__: the location Betamocks will save its cached response YAML files
- __services_config__: a YAML file that describes which services and endpoints to mock.
- __recording__: `true` or `false`, defaults to `false`.  When `true`, unmatched requests are sent out and responses recorded as new mock data.  Otherwise, unmatched requests fall back to a default response defined in `default.yml`.

``` ruby
Betamocks.configure do |config|
  config.enabled = true
  config.cache_dir = File.join(Rails.root, 'config', 'betamocks', 'cache')
  config.services_config = File.join(Rails.root, 'config', 'betamocks', 'betamocks.yml')
  config.recording = false
end
```

#### Services config
The services config is YAML file containing a list (array) of services.
Each item in the services list contains:
- __base_uri__: one or more host:port combinations for each environment of the API. NOTE: Including the port is important. The host+port have to match exactly and the system will _not_ infer anything. So for example, betamocks will not assume that an `https` endpoint will use port 443. You must specify it. 
- __endpoints__: a list of endpoints within the API to be mocked (all others will not be mocked).
Each endpoint will then describe its method and path.
  - __method__: HTTP method as a symbol :get, :post, :put, etc.
  - __path__: the path or URL fragment for the endpoint e.g. `/v0/users`.
  Wildcards are allowed for varying parameters within a URL e.g. `/v0/users/*/forms`
  will record both `/v0/users/42/forms` and `/v0/users/101/forms`.
  - __file_path__: a path from the root of the betamocks project to the directory where response files are located. 

```yaml
:services:
- :base_uri:
  - va.service.host.here:777
  :endpoints:
  - :method: :get
    :path: "/v0/users/*/forms"
    :file_path: "path/to/dir/in/betamocks"
```

#### Special considerations for request bodies with timestamps
Betamocks automatically records multiple unique responses per endpoint.
A response is considered unique if any of the following differ:
- params within the url; `/v0/users/42/forms` vs `/v0/users/101/forms`
- request header values (other than 'Authorization' or 'Date' which are automatically stripped)
- the request body

If the body contains a timestamp that changes on every request,
even though the rest of the body remains the same, it will cause Betamocks to record
a new cache file rather than loading the existing file. To get around this you can
add one or more regular expressions to strip out the timestamp.

For example SOAP request bodies often include a timestamp to ensure that a request is recent.

```xml
<versionCode code="3.0"/>
<creationTime value="20161028101201"/>
<interactionId extension="PRPA_IN201306UV02" root="2.16.840.1.113883.1.6"/>
<processingCode code="T"/>
```

To remove the timestamp in `creationTime` include a regular expression that captures the value in the service config file
in this case 14 digits `\d{14}` that follow `creationTime value=` or `creationTime value="(\d{14})"`:
```yaml
- :base_urls:
  - api.vets.gov
  :endpoints:
  - :method: :post
    :path: "/v0/stuffs"
    :timestamp_regex:
    - creationTime value="(\d{14})"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

In troubleshooting situtations, it may be convenient to cloning the repository locally and reference that location from the vets-api Gemfile. This makes it easy to use `byebug` etc to debug the repo.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/betamocks. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

