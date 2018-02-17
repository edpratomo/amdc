require 'pp'

class DiffReader
  def initialize
    @wordings = [
      [
        "match_started", proc {|val|
          <<"EOF"
Bros... match baru start!
#{val}
Enjoy the games dan jangan timeout ya!
EOF
        }
      ],
      [
        "contributors", proc {|val|
          <<"EOF"
Ada tambahan poin dari #{val}.
EOF
        }
      ],
      [
        "lost_games", proc {|val|
          <<"EOF"
Ada partai kalah: #{val}.
EOF
        }
      ],
      [
        "lost_timeout", proc {|val|
          <<"EOF"
Ada yang kalah jam: #{val}. Why?
EOF
        }
      ],
      [
        "score", proc {|val|
          <<"EOF"
Skor sekarang: #{val}.
EOF
        }
      ],
      [
        "winning", proc {|val|
          <<"EOF"
udah pasti menang kita, karena skor minimum #{val}.
EOF
        }
      ]
    ]
  end

  def after_save(ss)
    unless ss.diff.empty?
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
