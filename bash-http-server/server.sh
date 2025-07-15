#!/bin/bash

while true; do
  echo "Server up"
  {
    read -r request_line
    method=$(echo "$request_line" | awk '{print $1}')
    path=$(echo "$request_line" | awk '{print $2}')
    content_length=0

    while read -r header; do
      header=$(echo "$header" | tr -d '\r')
      if [[ "$header" =~ ^Content-Length:\ (.*)$ ]]; then
        content_length=${BASH_REMATCH[1]}
      fi
      [ -z "$header" ] && break
    done

    body=""
    if [ "$content_length" -gt 0 ]; then
      read -n "$content_length" body
    fi

    case "$method" in
      "GET")
        ./get_handler.sh "$path"
        ;;
      "POST")
        ./post_handler.sh "$path" "$body"
        ;;
      *)
        echo -e "HTTP/1.1 405 Method Not Allowed\r\n"
        ;;
    esac
  } | nc -l -p 8080 -q 0
done

