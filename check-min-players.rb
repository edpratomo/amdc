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
end
