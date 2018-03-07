require 'yaml'
require 'pp'
require 'json'
require 'clock_worker'
require 'date'
require 'logger'
require 'extension'

MY_CLUB = JSON.parse(File.read("config.json"))["club"]

raw = STDIN.read
parsed = JSON.parse(raw)
return unless parsed["status"] == "registration"

my_team = %w[team1 team2].find {|e| parsed["teams"][e]["@id"].split('/').last == ::MY_CLUB }
opponent = (%w[team1 team2] - [my_team]).first

if parsed["teams"][my_team]["players"].size < parsed["settings"]["min_team_players"].to_i
  delta = parsed["settings"]["min_team_players"].to_i - parsed["teams"][my_team]["players"].size
  url_snippet = "[#{parsed["url"]}](#{parsed["teams"][opponent]["name"].escape_telegram_markdown})"
  message = "Bros, kita masih kurang #{delta} pemain lagi untuk match melawan #{url_snippet}, " +
            "start tanggal #{parsed["start_time"].human_datetime.escape_telegram_markdown}"
  print message

  # schedule another check
  check_time = parsed["start_time"].to_i - 12 * 3600
  if Time.now.to_i < check_time
    $stderr.puts "[INFO] Scheduled for checking min players at #{check_time.human_datetime} in match against #{parsed["teams"][opponent]["name"]}"
    source_id = parsed['@id'].split('/').last
    ClockWorker.perform_at(check_time, source_id)
  end
end
