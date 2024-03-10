#!/bin/bash

# Check if all required arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <URL> <desired_status> <sleep_time>"
    exit 1
fi

URL=$1
DESIRED_STATUS=$2
SLEEP_TIME=$3

# Function to make requests
make_request() {
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" "$URL?status=$DESIRED_STATUS")
    echo "Request to $URL | Desired Status: $DESIRED_STATUS | Response Status: $response"
}

# Loop to make requests
while true; do
    make_request
    sleep "$SLEEP_TIME"
done
