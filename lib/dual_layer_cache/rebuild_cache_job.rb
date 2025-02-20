# app/jobs/rebuild_cache_job.rb
class RebuildCacheJob < ActiveJob::Base
  queue_as :default

  def perform(key, block)
    # We need to evaluate the block somehow
    # Since blocks can't be directly serialized, we'll assume it's stored elsewhere or passed differently
    value = block.call # This assumes the block is somehow preserved (see notes below)
    Rails.cache.write(key, value)
  end
end