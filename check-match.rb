
require 'active_record'
require 'ostruct'
require 'yaml'
require 'pp'
require 'optparse'
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
    hsh = @state.run_checks(previous, self)
    # pp hsh
    self.diff = JSON.pretty_generate(hsh)
  end
end

####################################################
# main

rails_env = ENV['RAILS_ENV'] || 'development'

cfg = YAML.load(File.read("db/config.yml"))
MY_CLUB = JSON.parse(File.read("config.json"))["club"]

ActiveRecord::Base.default_timezone = :local
ActiveRecord::Base.establish_connection(cfg[rails_env])

raw = STDIN.read
parsed = JSON.parse(raw)
source_id = parsed['@id'].split('/').last

match = Match.find_by(source_id: source_id)
unless match
  match = Match.new(source_id: source_id, name: parsed['name'])
  ss = Snapshot.new(match: match, raw: raw)
  ss.save!
else
  last_ss = Snapshot.where(match: match).order(:created_at).last
  unless last_ss
    ss = Snapshot.new(match: match, raw: raw)
    ss.save!
    return
  end
  if last_ss.raw != raw
    ss = Snapshot.new(match: match, raw: raw)
    ss.save!
    $stderr.puts "[INFO] Saved new snapshot."
  end
end
