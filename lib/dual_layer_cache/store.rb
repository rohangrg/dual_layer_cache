# lib/dual_layer_cache/store.rb
require 'active_support/cache'

module DualLayerCache
  class Store < ActiveSupport::Cache::Store
    @@blocks = {} # Store blocks for background rebuilding

    def self.blocks
      @@blocks
    end

    def initialize(base_store_options = {})
      @base_store = ActiveSupport::Cache::RedisCacheStore.new(base_store_options)
    end

    def read(key, options = nil)
      r1_key = "r1:#{key}"
      value = @base_store.read(r1_key, options)
      return value if value

      r2_key = "r2:#{key}"
      value = @base_store.read(r2_key, options)
      if value && @@blocks[key]
        RebuildCacheJob.perform_later(key, @@blocks[key])
      end
      value
    end

    def write(key, value, options = nil)
      r1_key = "r1:#{key}"
      r2_key = "r2:#{key}"
      @base_store.write(r1_key, value, options)
      @base_store.write(r2_key, value, options)
    end

    def fetch(key, options = nil, &block)
      @@blocks[key] = block if block_given?

      r1_key = "r1:#{key}"
      value = @base_store.read(r1_key, options)
      return value if value

      r2_key = "r2:#{key}"
      value = @base_store.read(r2_key, options)
      if value
        RebuildCacheJob.perform_later(key, @@blocks[key]) if @@blocks[key]
        return value
      end

      # Cold start: compute synchronously and store
      if block_given?
        value = block.call
        write(key, value, options)
        return value
      else
        raise "No block provided for cold start on key: #{key}"
      end
    end

    def delete(key, options = nil)
      r1_key = "r1:#{key}"
      @base_store.delete(r1_key, options)
    end

    def exist?(key, options = nil)
      r1_key = "r1:#{key}"
      @base_store.exist?(r1_key, options) || @base_store.exist?("r2:#{key}", options)
    end

    def clear(options = nil)
      @base_store.redis.keys("r1:*").each { |k| @base_store.delete(k, options) }
    end
  end
end