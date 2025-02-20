class RebuildCacheJob < ActiveJob::Base
  queue_as :default

  def perform(key, rebuilder_class_name)
    rebuilder = rebuilder_class_name.constantize
    value = rebuilder.call
    Rails.cache.write(key, value)
  end
end
