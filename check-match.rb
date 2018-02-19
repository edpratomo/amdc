require 'models'
require 'yaml'
require 'pp'
require 'optparse'
require 'erb'

rails_env = ENV['RAILS_ENV'] || 'development'

cfg = YAML.load(ERB.new(File.read("db/config.yml")).result)
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
    begin
      ss.save!
    rescue => err
      $stderr.puts "[INFO] #{err} - #{err.class}"
    else
      $stderr.puts "[INFO] Saved new snapshot."
    end
  end
end
