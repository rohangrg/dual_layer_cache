# DualLayerCache

DualLayerCache is a Ruby gem that provides a dual-layer caching system for Ruby on Rails applications using Redis. It implements a primary cache (R1) and a fallback cache (R2) to ensure high availability and minimal downtime during cache invalidation. When the primary cache is cleared, the fallback cache serves data instantly while the primary cache rebuilds in the background.

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'dual_layer_cache', git: 'https://github.com/rohangarg/dual_layer_cache.git', branch: 'main'
```

And then execute:

```bash
bundle install
```

## Usage

### Configuration
Configure Rails to use `DualLayerCache` as the cache store in `config/application.rb` or an environment-specific file (e.g., `config/environments/production.rb`):

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    # Other config...
    config.cache_store = DualLayerCache::Store.new(url: 'redis://localhost:6379/0')
  end
end
```

Ensure Redis is running and accessible at the specified URL (e.g., start Redis with `redis-server` if local).

### Basic Usage
Use `Rails.cache` methods (`fetch`, `read`, `write`) as usual. The dual-layer logic is handled automatically:

```ruby
class User < ApplicationRecord

  # ✅ **Simulate Heavy Computation**
  
  def self.heavy_computation
    sum = 0
    (1..60_000_000).each { |n| sum += Math.sqrt(n) }
    return sum.to_s + ' : ' +  Time.now.to_s
  end

  def self.cached_heavy_computation
    Rails.cache.fetch('user_heavy_computation', rebuilder: method(:heavy_computation)) do
      heavy_computation
    end
  end

end

```

### How It Works
- **Cold Start:** Both R1 and R2 are empty; data is computed, stored in both caches (`r1:my_data` and `r2:my_data`), and returned.
- **Cache Hit:** Data is read from R1 (`r1:my_data`) instantly.
- **Cache Clear:** `Rails.cache.delete('my_data')` clears R1; R2 (`r2:my_data`) serves the last known value while R1 rebuilds in the background via `RebuildCacheJob`.
- **Post-Clear Request:** Data is served from R2, ensuring no downtime, and R1 is repopulated asynchronously.

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/rohangarg/dual_layer_cache](https://github.com/rohangarg/dual_layer_cache). This project aims to be a safe, welcoming space for collaboration. Contributors are expected to adhere to the [Code of Conduct](https://github.com/rohangarg/dual_layer_cache/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DualLayerCache project's codebases, issue trackers, and communities is expected to follow the [Code of Conduct](https://github.com/rohangarg/dual_layer_cache/blob/main/CODE_OF_CONDUCT.md).
