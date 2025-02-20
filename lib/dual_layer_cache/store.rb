# lib/dual_layer_cache/store.rb
require 'active_support/cache'

module DualLayerCache
  class Store < ActiveSupport::Cache::Store
    @@rebuilders = {}

    def initialize(base_store_options = {})
      @base_store = ActiveSupport::Cache::RedisCacheStore.new(base_store_options)
    end

    # Indicate that this store supports cache versioning
    def self.supports_cache_versioning?
      true
    end

    def fetch(key, options = nil, &block)
      @@rebuilders[key] = options[:rebuilder] if options[:rebuilder]

      r1_key = normalize_key(key, options)
      value = @base_store.read(r1_key, options)
      return value if value

      r2_key = "r2:#{normalize_key(key, options)}"
      value = @base_store.read(r2_key, options)
      if value
        RebuildCacheJob.perform_later(key, @@rebuilders[key]) if @@rebuilders[key]
        return value
      end

      value = block.call
      write(key, value, options)
      value
    end

    def write(key, value, options = nil)
      r1_key = normalize_key(key, options)
      r2_key = "r2:#{normalize_key(key, options)}"
      @base_store.write(r1_key, value, options)
      @base_store.write(r2_key, value, options)
    end

    def read(key, options = nil)
      r1_key = normalize_key(key, options)
      value = @base_store.read(r1_key, options)
      return value if value

      r2_key = "r2:#{normalize_key(key, options)}"
      @base_store.read(r2_key, options)
    end

    def delete(key, options = nil)
      r1_key = normalize_key(key, options)
      @base_store.delete(r1_key, options)
    end

    def exist?(key, options = nil)
      r1_key = normalize_key(key, options)
      @base_store.exist?(r1_key, options) || @base_store.exist?("r2:#{r1_key}", options)
    end

    def clear(options = nil)
      @base_store.redis.keys("r1:*").each { |k| @base_store.delete(k, options) }
    end

    # Normalize the key to include version if provided
    def normalize_key(key, options = nil)
      return "r1:#{key}" unless options && options[:version]
      "r1:#{key}:#{options[:version]}"
    end
  end
end