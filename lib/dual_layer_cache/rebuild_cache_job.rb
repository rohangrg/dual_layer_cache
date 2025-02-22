class RebuildCacheJob < ActiveJob::Base
  queue_as :default

  def perform(key, rebuilder)
    if rebuilder.is_a?(Hash) && rebuilder[:klass] && rebuilder[:method]
      klass = rebuilder[:klass].constantize
      value = klass.send(rebuilder[:method])
      Rails.cache.write(key, value)
    else
      Rails.logger.error("Invalid rebuilder provided for key: #{key}")
    end
  end
end