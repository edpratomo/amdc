require 'active_record'
require 'yaml'
require 'pp'
require 'match_state'
require 'diff_reader'

class Match < ActiveRecord::Base
  has_many :snapshots
end

class Snapshot < ActiveRecord::Base
  belongs_to :match

  after_initialize :init_state
  before_save :generate_diff
  after_save DiffReader.new

  def previous
    @previous ||= Snapshot.where(match: match).where("created_at < NOW()").order(:created_at).last
  end

  def parsed
    @parsed ||= JSON.parse(raw)
  end

  private
  def init_state
    state_classes = {
      "registration" => MatchRegistration, 
      "in_progress" => MatchInProgress,
      "finished" => MatchFinished
    }
    @state = state_classes[parsed["status"]].new(my_team)
  end

  def my_team
    %w[team1 team2].find {|e| parsed["teams"][e]["@id"].split('/').last == ::MY_CLUB }
  end

  def generate_diff
    return true unless previous
    diff = @state.run_checks(previous, self)
    if diff.empty?
      $stderr.puts "[INFO] Changes detected, but irrelevant." if diff.empty?
      throw(:abort, "irrelevant changes")
    end
    self.diff = JSON.pretty_generate(diff)
  end
end
