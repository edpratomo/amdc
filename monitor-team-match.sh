#!/bin/bash

MATCH_ID=$1

if [ -z "$MATCH_ID" ]; then
  echo "please specify match ID"
  exit 1
fi

wget -O - "https://api.chess.com/pub/match/$MATCH_ID" | ruby -I. check-match.rb
