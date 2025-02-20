# lib/dual_layer_cache.rb
# frozen_string_literal: true

require 'active_support/cache'
require 'dual_layer_cache/store'
require 'dual_layer_cache/rebuild_cache_job'

# No need for additional code here; the store is now in ActiveSupport::Cache