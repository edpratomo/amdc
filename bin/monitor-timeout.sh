#!/bin/bash

MATCH_ID=$1

if [ -z "$MATCH_ID" ]; then
  echo "please specify match ID"
  exit 1
fi

CONFIG_FILE=config/high_timeout_rate.txt

if [ -f "$CONFIG_FILE" ];then
  for user in `cat "$CONFIG_FILE"`; do
    USERS="$USERS "$(echo -n "-u $user")
  done
fi

echo "$USERS" | xargs bundle exec ruby -Ilib check-timeout.rb -m "$MATCH_ID" -v -w 10
