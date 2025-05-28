# Betamocks

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)

Betamocks is Faraday middleware that mocks APIs by recording and replaying requests.
It's especially useful for local development to mock out APIs that are:
- Behind a VPN
- Unreliable or frequently unavailable
- Missing dev or staging environments
- Rate-limited or slow to respond

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
  - [Configuration](#configuration)
  - [Services Config](#services-config)
  - [Quick Start](#quick-start)
  - [Middleware Integration](#middleware-integration)
  - [UID Differentiation](#uid-differentiation)
  - [Error Simulation](#error-simulation)
  - [Logging](#logging)
  - [Handling Request Timestamps](#special-considerations-for-request-bodies-with-timestamps)
- [Development](#development)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

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

In a location that gets loaded before your Faraday connections are initialized (e.g. a Rails initializer),
configure the Betamocks settings:

| Setting | Description |
|---------|-------------|
| `enabled` | Globally turn Betamocks on (`true`) or off (`false`) |
| `cache_dir` | The location where Betamocks will save its cached response YAML files |
| `services_config` | Path to a YAML file that describes which services and endpoints to mock |
| `recording` | When `true`, unmatched requests are sent out and responses recorded as new mock data. When `false` (default), unmatched requests fall back to a default response defined in `default.yml` |

```ruby
Betamocks.configure do |config|
  config.enabled = true
  config.cache_dir = File.join(Rails.root, 'config', 'betamocks', 'cache')
  config.services_config = File.join(Rails.root, 'config', 'betamocks', 'betamocks.yml')
  config.recording = false
end
```

#### Services config

The services config is a YAML file containing a list (array) of services.
Each service definition includes:

- **base_urls**: One or more host:port combinations for each environment of the API.
- **endpoints**: A list of endpoints within the API to be mocked (all others will not be mocked).

Each endpoint must specify:
- **method**: HTTP method as a symbol (:get, :post, :put, etc.)
- **path**: The path or URL fragment for the endpoint (e.g., `/v0/users`).
  - Wildcards are allowed for varying parameters within a URL (e.g., `/v0/users/*/forms` will match both `/v0/users/42/forms` and `/v0/users/101/forms`)
- **response_delay**: (Optional) Delay in seconds before sending the response (useful to simulate real-world delays)
- **cache_multiple_responses**: (Optional) Configuration for caching multiple different responses based on request content (see [UID Differentiation](#uid-differentiation) section)

Example configuration:

```yaml
:services:
- :base_urls:
  - va.service.that.timesout
  - int.va.service.that.timesout
  :endpoints:
  - :method: :get
    :path: "/v0/users/*/forms"
    :response_delay: 2
- :base_urls:
  - bnb.data.bl.uk
  :endpoints:
  - :method: :get
    :path: "/doc/resource/*"
```

### Quick Start

To quickly implement Betamocks in your application:

1. Add the gem to your Gemfile and run `bundle install`
2. Create a configuration file (e.g., in `config/initializers/betamocks.rb`):

```ruby
Betamocks.configure do |config|
  config.enabled = true
  config.recording = true  # Start in recording mode to capture real responses
  config.cache_dir = Rails.root.join('mock_responses')
  config.services_config = Rails.root.join('config', 'betamocks.yml')
end
```

3. Create a basic services config file (e.g., in `config/betamocks.yml`):

```yaml
:services:
- :base_urls:
  - api.example.com
  :endpoints:
  - :method: :get
    :path: "/v1/users"
  - :method: :post
    :path: "/v1/users"
```

4. Add Betamocks middleware to your Faraday connection:

```ruby
connection = Faraday.new('https://api.example.com') do |conn|
  conn.use Betamocks::Middleware
  conn.adapter Faraday.default_adapter
end
```

5. After making API calls with recording enabled, switch to replay mode:

```ruby
Betamocks.configure do |config|
  config.recording = false  # Now use recorded responses
end
```

### Middleware Integration

To use Betamocks in your application, you need to add it to your Faraday connection stack. Here are examples for different frameworks:

#### Basic Faraday Integration

```ruby
connection = Faraday.new(url: 'https://api.example.com') do |conn|
  conn.use Betamocks::Middleware
  # Add other middleware as needed
  conn.adapter Faraday.default_adapter
end
```

#### Rails with Faraday

```ruby
# config/initializers/faraday.rb
module MyApp
  def self.api_connection
    Faraday.new(url: Rails.configuration.api_url) do |conn|
      conn.use Betamocks::Middleware
      conn.response :json, content_type: /\bjson$/
      conn.adapter Faraday.default_adapter
    end
  end
end
```

### UID Differentiation

Betamocks can differentiate between different requests to the same endpoint by using unique identifiers (UIDs) extracted from the request. This feature is useful when an API endpoint returns different responses based on request content.

#### Configuring UID Differentiation

To enable UID differentiation, add the `cache_multiple_responses` configuration to an endpoint:

```yaml
:endpoints:
- :method: :post
  :path: "/v0/users"
  :cache_multiple_responses:
    :uid_location: body
    :uid_locator: "id\":\"([^\"]+)"
```

The configuration requires:

| Setting | Description |
|---------|-------------|
| `uid_location` | Where to find the UID: `body`, `header`, `query`, or `url` |
| `uid_locator` | How to extract the UID from the specified location |
| `optional_code_locator` | (Optional) Additional regex to further differentiate between similar requests |

The `uid_locator` value depends on the `uid_location`:
- For `body` and `url`: A regex with a capture group `()` to extract the UID
- For `header`: The name of the header to use as UID
- For `query`: The name of the query parameter to use as UID

#### Examples

1. **Extracting user ID from JSON body**:
```yaml
:cache_multiple_responses:
  :uid_location: body
  :uid_locator: "userId\":\"([^\"]+)"
```
Extracts `12345` from `{"userId":"12345"}`

2. **Extracting ID from URL path**:
```yaml
:cache_multiple_responses:
  :uid_location: url
  :uid_locator: "/users/([^/]+)"
```
Extracts `42` from `/users/42/profile`

3. **Using query parameter**:
```yaml
:cache_multiple_responses:
  :uid_location: query
  :uid_locator: "user_id"
```
Uses the value of the `user_id` query parameter as the UID

4. **Using additional differentiation**:
```yaml
:cache_multiple_responses:
  :uid_location: body
  :uid_locator: "userId\":\"([^\"]+)"
  :optional_code_locator: "requestType\":\"([^\"]+)"
```
First extracts the UID, then further organizes by `requestType` value

#### Cache File Structure

When UID differentiation is enabled, Betamocks organizes cache files as follows:

```
cache_dir/
  endpoint_path/
    uid1.yml
    uid2.yml
    ...
```

With optional locators:

```
cache_dir/
  endpoint_path/
    optional_locator_value1/
      uid1.yml
      uid2.yml
    optional_locator_value2/
      uid1.yml
      uid2.yml
    ...
```

#### Handling Multiple Resources at One Endpoint

For endpoints that serve multiple resource types, you can create multiple endpoint entries with different `file_path` and UID configurations:

```yaml
:endpoints:
- :method: :post
  :path: "/get_animals"
  :file_path: "/pics/zebras"
  :cache_multiple_responses:
    :uid_location: body
    :uid_locator: '<AnimalType>Zebra<\/AnimalType><Id>(\d{8})'
- :method: :post
  :path: "/get_animals"
  :file_path: "/pics/lions"
  :cache_multiple_responses:
    :uid_location: body
    :uid_locator: '<AnimalType>Lion<\/AnimalType><Id>(\d{8})'
```

This creates separate caches for different resources accessed through the same endpoint.

### Error Simulation

Betamocks can simulate error responses, which is useful for testing error handling in your application.

To configure an error response, add an `error` section to your endpoint:

```yaml
:endpoints:
- :method: :get
  :path: "/v0/users/*/forms"
  :file_path: "users/form"
  :error:
    :status: 400
    :body: '{"error": "Bad Request"}'
```

Betamocks will raise appropriate Faraday errors based on the status code:
- 404 raises `Faraday::Error::ResourceNotFound`
- 407 raises `Faraday::Error::ConnectionFailed`
- Other status codes raise `Faraday::Error::ClientError`

### Logging

Betamocks includes a logging system to help with debugging. By default, logs are sent to STDOUT, but you can configure a custom logger:

```ruby
Betamocks.configure do |config|
  # Other configuration...
  config.logger = Rails.logger # Or any other Logger instance
end
```

The logs provide information about:
- Response delays being simulated
- Mock errors being raised
- Issues with loading cache files

### Special considerations for request bodies with timestamps

Betamocks automatically records multiple unique responses per endpoint.
A response is considered unique if any of the following differ:
- Parameters within the URL (e.g., `/v0/users/42/forms` vs `/v0/users/101/forms`)
- Request header values (other than 'Authorization' or 'Date' which are automatically stripped)
- The request body

If the body contains a timestamp that changes on every request but the rest of the content remains the same, Betamocks will record a new cache file for each request. To prevent this, you can add one or more regular expressions to strip out timestamps.

#### Example: Handling SOAP Timestamps

SOAP request bodies often include a timestamp to ensure the request is recent:

```xml
<versionCode code="3.0"/>
<creationTime value="20161028101201"/>
<interactionId extension="PRPA_IN201306UV02" root="2.16.840.1.113883.1.6"/>
<processingCode code="T"/>
```

To handle this, include a `timestamp_regex` that captures the timestamp value:

```yaml
:endpoints:
- :method: :post
  :path: "/v0/stuffs"
  :timestamp_regex:
  - creationTime value="(\d{14})"
```

This regex will match and remove the 14-digit timestamp that follows "creationTime value=".

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Troubleshooting

### Common Issues

1. **Missing default response**  
   If a request doesn't match any recorded response and `recording` is disabled, Betamocks will try to use a default response. Ensure you have a `default.yml` file in your cache directory.

2. **Unable to differentiate between similar requests**  
   If you're getting inconsistent responses, check your UID configuration. Make sure your `uid_locator` regular expression is specific enough to extract unique identifiers.

3. **No response being recorded**  
   Check that both the `enabled` and `recording` options are set to `true` during the recording phase.

4. **Regular expressions not matching correctly**  
   When using regular expressions for UIDs or timestamps, test them thoroughly. Tools like [Rubular](https://rubular.com/) can help verify your regex patterns.

5. **Timeouts or connection errors during recording**  
   If you're experiencing timeouts when recording real API responses, consider adding a longer timeout to your Faraday connection:
   ```ruby
   Faraday.new do |conn|
     conn.options[:timeout] = 30
     conn.use Betamocks::Middleware
     # other middleware...
   end
   ```

6. **Cannot find cached response files**  
   Verify that your cache directory structure matches what Betamocks expects. The path should be: 
   ```
   cache_dir/endpoint_path/response.yml
   ```
   
   You can enable debug logging to see what paths Betamocks is trying to access:
   ```ruby
   Betamocks.configure do |config|
     config.logger.level = Logger::DEBUG
   end
   ```

7. **Middleware order issues**  
   The order of middleware in your Faraday stack matters. Betamocks should generally be placed before other middleware that might modify the request or response:
   ```ruby
   Faraday.new do |conn|
     conn.use Betamocks::Middleware
     conn.use SomeOtherMiddleware  # This runs after Betamocks
     conn.adapter Faraday.default_adapter
   end
   ```

8. **Handling binary responses**  
   By default, Betamocks works best with text-based responses. For binary responses (like images), you may need to use Base64 encoding/decoding.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/department-of-veterans-affairs/betamocks. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

### Contribution Guidelines

1. **Fork the repository** and create your branch from `master`.
2. **Write tests** for any new functionality.
3. **Ensure the test suite passes** by running `rake spec`.
4. **Update the documentation** to reflect any changes.
5. **Submit a pull request** with a clear description of the changes.

### Reporting Issues

When reporting issues, please include:
- A clear, descriptive title
- Steps to reproduce the behavior
- Expected behavior
- Actual behavior
- Your Ruby and Faraday versions
- Any relevant code snippets or configuration

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
