#!/bin/bash

if [ -z "$AMDC_BOT_TOKEN" ];then
  echo "AMDC_BOT_TOKEN is not defined!"
  exit 1
fi
if [ -z "$AMDC_CHAT_ID" ];then
  echo "AMDC_CHAT_ID is not defined!"
  exit 1
fi

send_message() {
  curl -X POST -H "Content-Type: application/x-www-form-urlencoded; charset=utf-8" \
    "https://api.telegram.org/bot${AMDC_BOT_TOKEN}/sendMessage" -d "parse_mode=Markdown" \
    -d "chat_id=${AMDC_CHAT_ID}" \
    --data-urlencode "text=${MSG_TEXT}"
}

get_me() {
  curl "https://api.telegram.org/bot${AMDC_BOT_TOKEN}/getMe"
}

MSG_TEXT=$(cat)
send_message
