class String
  # https://core.telegram.org/bots/api#markdown-style
  def escape_telegram_markdown
    self.gsub('_', '\_').gsub('*', '\*').gsub('[', '\[').gsub(']', '\]').gsub('`', '\`')
  end
end
