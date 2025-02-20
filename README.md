# DualLayerCache

DualLayerCache is a Ruby gem that provides a dual-layer caching system for Ruby on Rails applications using Redis. It implements a primary cache (R1) and a fallback cache (R2) to ensure high availability and minimal downtime during cache invalidation. When the primary cache is cleared, the fallback cache serves data instantly while the primary cache rebuilds in the background.

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'dual_layer_cache'
```

And then execute:

```bash
bundle install
```

Or install it directly using:

```bash
gem install dual_layer_cache
```

If you prefer to install from the GitHub repository (e.g., before an official RubyGems release), add this to your `Gemfile`:

```ruby
gem 'dual_layer_cache', git: 'https://github.com/rohangarg/dual_layer_cache.git', branch: 'main'
```

## Usage

### Configuration
Configure Rails to use `DualLayerCache` as the cache store in `config/application.rb` or an environment-specific file (e.g., `config/environments/production.rb`):

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    # Other config...
    config.cache_store = :dual_layer_cache_store, { url: 'redis://localhost:6379/0' }
  end
end
```

Ensure Redis is running and accessible at the specified URL (e.g., start Redis with `redis-server` if local).

### Basic Usage
Use `Rails.cache` methods (`fetch`, `read`, `write`) as usual. The dual-layer logic is handled automatically:

```ruby
# Example in a controller or service
data = Rails.cache.fetch('my_data', rebuilder: MyDataComputer) do
  MyDataComputer.call # Expensive operation, e.g., API call taking 10 seconds
end
puts data # => { data: "Latest Value" }

# Read cached data
cached_data = Rails.cache.read('my_data')
puts cached_data # => { data: "Latest Value" }

# Invalidate cache (clears R1 only)
Rails.cache.delete('my_data')
# Next read will use R2 and trigger background rebuild
```

Define a rebuilder class to regenerate data in the background (e.g., `app/services/my_data_computer.rb`):

```ruby
# app/services/my_data_computer.rb
class MyDataComputer
  def self.call
    sleep(10) # Simulate expensive computation (e.g., external API call)
    { data: 'Latest Value' } # Return data to cache
  end
end
```

### How It Works
- **Cold Start:** Both R1 and R2 are empty; data is computed, stored in both caches (`r1:my_data` and `r2:my_data`), and returned.
- **Cache Hit:** Data is read from R1 (`r1:my_data`) instantly.
- **Cache Clear:** `Rails.cache.delete('my_data')` clears R1; R2 (`r2:my_data`) serves the last known value while R1 rebuilds in the background via `RebuildCacheJob`.
- **Post-Clear Request:** Data is served from R2, ensuring no downtime, and R1 is repopulated asynchronously.

### Integration with Jbuilder
Works seamlessly with `jbuilder` for JSON caching. Example in a controller and view:

```ruby
# app/controllers/api_controller.rb
class ApiController < ApplicationController
  def show
    @data = Rails.cache.fetch('my_data', rebuilder: MyDataComputer) do
      MyDataComputer.call
    end
    render 'show'
  end
end
```

```ruby
# app/views/api/show.json.jbuilder
json.cache! 'my_data' do
  json.data @data[:data] # Outputs: {"data": "Latest Value"}
end
```

### Requirements
- **Rails:** 6.0 or higher
- **Redis:** 4.0 or higher
- **ActiveJob:** Configured (e.g., with Sidekiq) for background cache rebuilding. Example Sidekiq setup:
  ```ruby
  # config/sidekiq.yml
  :queues:
    - default
  ```
  Start Sidekiq with: `bundle exec sidekiq`.

## Development

After cloning the repo, run `bin/setup` to install dependencies (if a `bin/setup` script exists; otherwise, use `bundle install`). Then, run `rake spec` to execute tests (after adding a test suite, e.g., with RSpec). Use `bin/console` for an interactive prompt:

```bash
bundle exec bin/console
```

Example console usage:
```ruby
irb(main):001:0> Rails.cache.fetch('test', rebuilder: MyDataComputer) { { data: 'Test' } }
=> { data: "Test" }
```

To install the gem locally:

```bash
bundle exec rake install
```

To release a new version:
1. Update the version in `lib/dual_layer_cache/version.rb`:
   ```ruby
   module DualLayerCache
     VERSION = "0.2.0" # Increment as needed
   end
   ```
2. Run:
   ```bash
   bundle exec rake release
   ```
   This creates a git tag, pushes changes, and publishes the gem to [RubyGems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/rohangarg/dual_layer_cache](https://github.com/rohangarg/dual_layer_cache). This project aims to be a safe, welcoming space for collaboration. Contributors are expected to adhere to the [Code of Conduct](https://github.com/rohangarg/dual_layer_cache/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DualLayerCache project's codebases, issue trackers, and communities is expected to follow the [Code of Conduct](https://github.com/rohangarg/dual_layer_cache/blob/main/CODE_OF_CONDUCT.md).