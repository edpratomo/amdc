require 'pp'

class MatchState
  attr_reader :my_team

  def initialize(my_team)
    @my_team = my_team
  end

  def compare_teams(old, new, key)
    old["teams"]["team1"][key] != new["teams"]["team1"][key] or
    old["teams"]["team2"][key] != new["teams"]["team2"][key]
  end

  def checks
    []
  end

  def run_checks(prev_ss, ss)
    checks.inject({}) do |m,o|
      k, v = o.call(prev_ss.parsed, ss.parsed)
      m[k] = v if k
      m
    end
  end
end

class MatchInProgress < MatchState
  attr_reader :recent_contributors, :recent_lost, :recent_timeout

  def initialize(my_team)
    @recent_lost = {}
    @recent_timeout = {}
    @recent_contributors = {}
    super
  end

  def add_recent_lost(username)
    @recent_lost[username] ||= 0
    @recent_lost[username] += 1
  end

  def add_recent_timeout(username)
    @recent_timeout[username] ||= 0
    @recent_timeout[username] += 1
  end

  def add_recent_contributor(username, val)
    @recent_contributors[username] ||= 0
    @recent_contributors[username] += val
  end

  def scan_players_results(old, new)
    active_players_in_my_team = old["teams"][my_team]["players"].reject {|e|
      e.has_key?("played_as_black") and e.has_key?("played_as_white")
    }
    active_boards = active_players_in_my_team.map {|e| e["board"].split('/').last }.sort_by(&:to_i)

    opponent_team = (old["teams"].keys - [my_team]).first
    opponent_players = new["teams"][opponent_team]["players"].inject({}) {|m,o|
      board_num = o["board"].split('/').last
      if active_boards.include?(board_num)
        m[board_num] = o
      end
      m
    }
    my_team_players = new["teams"][my_team]["players"].inject({}) {|m,o|
      board_num = o["board"].split('/').last
      if active_boards.include?(board_num)
        m[board_num] = o
      end
      m
    }
    active_players_in_my_team.each do |e|
      board_num = e["board"].split('/').last

      %w[played_as_white played_as_black].each do |color|
        if not e.has_key?(color) and my_team_players[board_num].has_key?(color)
          if my_team_players[board_num][color] == "win"
            add_recent_contributor(e["username"], 1)
          elsif my_team_players[board_num][color] == "timeout"
            add_recent_timeout(e["username"])
          else
            # check opponent result
            opponent_color = if color == 'played_as_white'
              'played_as_black'
            else
              'played_as_white'
            end
            if opponent_players[board_num][opponent_color] == "win"
              add_recent_lost(e["username"])
            else
              add_recent_contributor(e["username"], 0.5)
            end
          end
        end
      end
    end
  end

  def checks
    [
      lambda {|old,new|
        if old["status"] == "registration"
          return "match_started", "#{new["name"]} (#{Time.at(new["start_time"].to_i).to_datetime.strftime('%d %b %Y, %H:%M UTC%:z')})"
        end
      },
      lambda {|old,new|
        if compare_teams(old, new, "score")
          return "score", 
            "#{new["teams"]["team1"]["name"]} vs #{new["teams"]["team2"]["name"]} : " +
            "#{new["teams"]["team1"]["score"]} - #{new["teams"]["team2"]["score"]}"
        end
      },
      lambda {|old,new|
        draw_score = new["boards"] / 2.0
        if old["teams"][my_team]["score"] <= draw_score and
           new["teams"][my_team]["score"] > draw_score
          return "winning", "#{draw_score + 0.5}" # score required to win
        end
      },
      lambda {|old,new|
        if compare_teams(old, new, "score")
          scan_players_results(old, new)
          unless recent_contributors.empty?
            return "contributors", recent_contributors.inject([]) {|m,o|
              m.push "#{o[0]} (#{o[1]})"
              m
            }.join(", ")
          end
        end
      },
      lambda {|old,new|
        unless recent_lost.empty?
          return "lost_games", recent_lost.inject([]) {|m,o|
            m.push "#{o[0]} (#{o[1]} games)"
            m
          }.join(", ")
        end
      },
      lambda {|old,new|
        unless recent_timeout.empty?
          return "timeout_games", recent_timeout.inject([]) {|m,o|
            m.push "#{o[0]} (#{o[1]} games)"
            m
          }.join(", ")
        end
      }
    ]
  end
end

class MatchRegistration < MatchState

end

class MatchFinished < MatchInProgress; end
