#!/bin/bash

MATCH_ID=$1

if [ -z "$MATCH_ID" ]; then
  echo "please specify match ID"
  exit 1
fi

if [ "$RAILS_ENV" == "production" ];then
  curl -sSL "https://api.chess.com/pub/match/$MATCH_ID" | bundle exec ruby -Ilib check-min-players.rb | ./bin/telegram-bot.sh
else
  curl -sSL "https://api.chess.com/pub/match/$MATCH_ID" | bundle exec ruby -Ilib check-min-players.rb
fi
