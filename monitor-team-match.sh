#!/bin/bash

MATCH_ID=$1

if [ -z "$MATCH_ID" ]; then
  echo "please specify match ID"
  exit 1
fi

curl -sSL "https://api.chess.com/pub/match/$MATCH_ID" | bundle exec ruby -Ilib check-match.rb
