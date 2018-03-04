require 'sidekiq'
require 'sidekiq-status'

class ClockWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(match_id)
    system("bin/monitor-min-players.sh", match_id)
  end
end
