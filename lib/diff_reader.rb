require 'pp'
require 'extension'

class DiffReader
  def initialize
    @wordings = [
      [
        "registration_closed", proc {|val|
          /^(.+)\((\d+) boards\)/.match(val) do |md|
          <<"EOF"
Registrasi untuk *#{md[1].escape_telegram_markdown}* ditutup. Total #{md[2]} papan.
EOF
          end
        }
      ],
      [
        "match_started", proc {|val|
          <<"EOF"
Bros... match baru start!
#{val.escape_telegram_markdown}
Enjoy the games dan jangan timeout ya!
EOF
        }
      ],
      [
        "contributors", proc {|val|
          <<"EOF"
Ada tambahan poin dari #{val.escape_telegram_markdown} \u{1F44D}
EOF
        }
      ],
      [
        "lost_games", proc {|val|
          <<"EOF"
Ada partai kalah: #{val.escape_telegram_markdown} \u{1F614}
EOF
        }
      ],
      [
        "lost_timeout", proc {|val|
          <<"EOF"
Ada yang kalah jam: #{val.escape_telegram_markdown} \u{23F0} Why?
EOF
        }
      ],
      [
        "score", proc {|val|
          <<"EOF"
Skor sekarang: #{val.escape_telegram_markdown}.
EOF
        }
      ],
      [
        "winning", proc {|val|
          <<"EOF"
Horee menang.. \u{1F389} (point minimum utk menang: #{val})
EOF
        }
      ]
    ]
  end

  def after_save(ss)
    if ss.diff
      obj = JSON.parse(ss.diff)
      print translate(obj)
    end
  end

  private
  def translate(obj)
    @wordings.inject('') do |m,o|
      key, say_proc = o
      val = obj[key]
      m += say_proc.call(val) if val
      m
    end
  end
end
