require 'date'

class String
  # https://core.telegram.org/bots/api#markdown-style
  def escape_telegram_markdown
    self.gsub('_', '\_').gsub('*', '\*').gsub('[', '\[').gsub(']', '\]').gsub('`', '\`')
  end
end

class Integer
  def human_datetime
    Time.at(self).to_datetime.strftime('%d %b %Y, %H:%M UTC%:z')
  end
end
