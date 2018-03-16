require 'faraday'
require 'faraday_middleware'

module Helper
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
end
