require 'active_support/cache'

module DualLayerCache
  class Store < ActiveSupport::Cache::Store
    # Store rebuilders for background jobs
    @@rebuilders = {}

    def self.register_rebuilder(key, rebuilder)
      @@rebuilders[key] = rebuilder
    end

    def self.rebuilders
      @@rebuilders
    end

    def initialize(base_store_options = {})
      @base_store = ActiveSupport::Cache::RedisCacheStore.new(base_store_options)
    end

    # Read from R1, fallback to R2
    def read(key, options = nil)
      r1_key = "r1:#{key}"
      value = @base_store.read(r1_key, options)
      return value if value

      r2_key = "r2:#{key}"
      value = @base_store.read(r2_key, options)
      if value && @@rebuilders[key]
        # Trigger background rebuild when falling back to R2
        RebuildCacheJob.perform_later(key, @@rebuilders[key].to_s)
      end
      value
    end

    # Write to both R1 and R2
    def write(key, value, options = nil)
      r1_key = "r1:#{key}"
      r2_key = "r2:#{key}"
      @base_store.write(r1_key, value, options)
      @base_store.write(r2_key, value, options)
    end

    # Fetch with dual-layer logic
    def fetch(key, options = nil, &block)
      # Register rebuilder if provided
      if options[:rebuilder]
        @@rebuilders[key] = options[:rebuilder]
      end

      r1_key = "r1:#{key}"
      value = @base_store.read(r1_key, options)
      return value if value

      r2_key = "r2:#{key}"
      value = @base_store.read(r2_key, options)
      if value
        # Use R2 and rebuild R1 in background
        if @@rebuilders[key]
          RebuildCacheJob.perform_later(key, @@rebuilders[key].to_s)
        end
        return value
      end

      # Cold start: compute, store, return
      value = block.call
      write(key, value, options)
      value
    end

    # Clear R1 only
    def delete(key, options = nil)
      r1_key = "r1:#{key}"
      @base_store.delete(r1_key, options)
    end

    # Pass-through for other methods
    def exist?(key, options = nil)
      r1_key = "r1:#{key}"
      @base_store.exist?(r1_key, options) || @base_store.exist?("r2:#{key}", options)
    end

    def clear(options = nil)
      # Optionally clear both layers; for now, only R1
      @base_store.redis.keys("r1:*").each { |k| @base_store.delete(k, options) }
    end
  end
end