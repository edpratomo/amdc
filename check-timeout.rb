require 'faraday'
require 'faraday_middleware'
require 'optparse'
require 'ostruct'
require 'pp'
require 'extension'
require 'logger'

def games_to_move(player)
  urls = retrieve(player["board"])["games"].reject {|e| e.has_key?("end_time")}.map {|e| e["url"]}
  retrieve(games_to_move_url(player["username"]))["games"].select {|e| urls.include?(e["url"])}
end

def retrieve(url)
  conn = Faraday.new(url: url) do |c|
           c.use FaradayMiddleware::ParseJson
           c.use FaradayMiddleware::FollowRedirects, limit: 3
           c.use Faraday::Response::RaiseError # raise exceptions on 40x, 50x responses
           c.use Faraday::Adapter::NetHttp
           c.headers['Content-Type'] = "application/json"
         end
  response = conn.get
  response.body
end

def team_match_api_url(match_id)
  "https://api.chess.com/pub/match/#{match_id}"
end

def player_url(username)
  "https://api.chess.com/pub/player/#{username}"
end

def games_to_move_url(username)
  "https://api.chess.com/pub/player/#{username}/games/to-move"
end

def sec2hm(secs)
  time = secs.round
  time /= 60
  mins = time % 60
  time /= 60
  hrs = time
  [ hrs, mins ]
end

######################
# main

logger = Logger.new(STDOUT, Logger::DEBUG)
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
usernames = options.usernames.select {|e| retrieve(player_url(e))["status"] == "basic"}

monitored_players = {}

options.match_ids.each do |match_id|
  match = retrieve(team_match_api_url(match_id))
  next if match["status"] == "finished"
  %w[team1 team2].each do |team|
    players = match["teams"][team]["players"].
      reject {|e| e["played_as_white"] and e["played_as_black"]}.
      select {|e| usernames.include?(e["username"])}.
      reject {|e| monitored_players.has_key?(e["username"]) and monitored_players[e["username"]][match["name"]]}
    
    if VERBOSE
      logger.info "players: #{players}"
    end

    players.each do |player|
      monitored_players[player["username"]] ||= {}
      monitored_players[player["username"]][match["name"]] = []

      games_to_move(player).each do |game|
        now = Time.now.to_i
        delta_in_seconds = game["move_by"] - now
        unless delta_in_seconds > options.warn_threshold * 3600
          monitored_players[player["username"]][match["name"]].push(delta_in_seconds)
        end
      end
    end
  end
end

# pp monitored_players

monitored_players.each do |username, match|
  match.each do |match_name, timelefts|
    unless timelefts.empty?
      timeleft = timelefts.sort.first # pick the shortest time left
      hour, min = sec2hm(timeleft)
      puts "#{username}: #{hour} jam, #{min} menit di match: #{match_name}"
    end
  end
end
