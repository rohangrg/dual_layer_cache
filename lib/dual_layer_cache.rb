require 'dual_layer_cache/store'
require 'dual_layer_cache/rebuild_cache_job'

ActiveSupport::Cache::Store.inherited(DualLayerCache::Store)
