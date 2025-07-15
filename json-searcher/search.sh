#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <json_file> <attribute>"
    exit 1
fi

JSON_FILE=$1
ATTRIBUTE=$2

if [ ! -f "$JSON_FILE" ]; then
    echo "Error: File '$JSON_FILE' not found."
    exit 1
fi

jq ".$ATTRIBUTE" "$JSON_FILE"
