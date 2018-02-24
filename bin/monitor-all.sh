#!/bin/bash

CONFIG_FILE=config/matches_list.txt

if [ -f "$CONFIG_FILE" ];then
  IFS=$'\n'; for line in `cat "$CONFIG_FILE"`; do
    match_id=$(echo "$line" | awk '{print $1}')
    desc=$(echo "$line" | cut -d ' ' -f 2-)

    echo "$desc"
    if [ "$RAILS_ENV" == "production" ];then
      . ./bin/monitor-team-match.sh $match_id | ./bin/telegram-bot.sh
      . ./bin/monitor-timeout.sh $match_id | ./bin/telegram-bot.sh
    else
      . ./bin/monitor-team-match.sh $match_id 
      . ./bin/monitor-timeout.sh $match_id
    fi
  done
fi
