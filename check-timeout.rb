require 'optparse'
require 'ostruct'
require 'pp'
require 'extension'
require 'logger'
require 'helper'

include Helper

def sec2hm(secs)
  time = secs.round
  time /= 60
  mins = time % 60
  time /= 60
  hrs = time
  [ hrs, mins ]
end

def say_in_telegram(username, match, url, timeleft)
  hour, min = sec2hm(timeleft)
  "Bro *#{username.escape_telegram_markdown}* tinggal punya sisa waktu #{hour} jam #{min} menit " +
  "[#{match.escape_telegram_markdown}](#{url})\n"
end

######################
# main

logger = Logger.new(STDERR, Logger::DEBUG)
options = OpenStruct.new

OptionParser.new do |opts|
  opts.separator ""
  opts.separator "Options are ..."
  opts.on_tail("-h", "--help", "-H", "Display this help message.") do
    puts opts
    exit
  end
  opts.on('-u', '--username USERNAME', 'Username on chess.com') {|val|
    options.usernames ||= []
    options.usernames.push(val)
  }
  opts.on('-m', '--match MATCH_ID', 'Match ID') {|val|
    options.match_ids ||= []
    options.match_ids.push(val)
  }
  opts.on('-w', '--warning WARNING', 'Warning threshold, in number of hours left. Default to 3 hours.') {|val|
    options.warn_threshold = val.to_i
  }
  opts.on('-v', '--verbose', 'Verbose output') do
    options.verbose = true
  end
end.parse!

options.warn_threshold ||= 3 # default 3 hours left
unless options.match_ids
  $stderr.puts "Match ID is not specified."
  exit 1
end
unless options.usernames
  $stderr.puts "Username is not specified."
  exit 1
end

VERBOSE = options.verbose

# only check 'basic' users
# usernames = options.usernames.select {|e| retrieve(player_url(e))["status"] == "basic"}

# skip closed accounts
usernames = options.usernames.reject {|e| retrieve(player_url(e))["status"] =~ /^closed/}

monitored_players = options.match_ids.inject({}) do |m,match_id|
  match = retrieve(team_match_api_url(match_id))
  next m unless match["status"] == "in_progress"
  %w[team1 team2].each do |team|
    players = match["teams"][team]["players"].
      reject {|e| e["played_as_white"] and e["played_as_black"]}.
      select {|e| usernames.include?(e["username"])}.
      reject {|e| m.has_key?(e["username"]) and m[e["username"]][match["name"]]}
    
    if VERBOSE
      unless players.empty?
        logger.info "Match *#{match["name"]}* - players on #{team}: #{players.map {|e| e["username"]}.sort.join(', ')}"
      end
    end

    players.each do |player|
      games_to_move(player).each do |game|
        next if game["move_by"] == 0
        now = Time.now.to_i
        delta_in_seconds = game["move_by"] - now
        next if delta_in_seconds < 0
        unless delta_in_seconds > options.warn_threshold * 3600
          m[player["username"]] ||= {}
          m[player["username"]][match["name"]] = []
          m[player["username"]][match["name"]].push([ game["url"], delta_in_seconds ])
        end
      end
    end
  end
  m
end

message = monitored_players.inject('') do |m,o|
  username, match = o
  match.each do |match_name, games|
    unless games.empty?
      game = games.sort_by(&:last).first # pick the shortest time left
      m += say_in_telegram(username, match_name, game[0], game[1])
    end
  end
  m
end

print 'TIMEOUT WARNING!! ' + message unless message.empty?
