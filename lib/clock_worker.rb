require 'sidekiq'
require 'sidekiq-status'

Sidekiq.configure_client do |config|
  config.redis = { :size => 1 }
end

Sidekiq.configure_server do |config|
  config.redis = { :size => 1 }
end

class ClockWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(match_id)
    system("bin/monitor-min-players.sh", match_id)
  end
end
