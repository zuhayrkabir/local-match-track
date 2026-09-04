#!/bin/bash

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "require 2 arguments." 1>&2
    echo "./buildEnv.sh /path/to/.env /output/path" 1>&2
    exit 1
fi

env_file="$1"
output_dir="$2"

ditto_database_id=""
ditto_server_url=""
ditto_playground_token=""

if [ -f "$env_file" ]; then
    while IFS='' read -r line || [[ -n "$line" ]]; do
        line="${line//[$'\r\n']/}"
        trimline="${line//[$'\t\r\n ']/}"
        if [ -n "$trimline" ] && [[ $trimline != \#* ]]; then
            key="${line%%=*}"
            value="$(echo "${line#*=}" | sed 's/^[[:space:]]*//; s/^"//; s/"$//')"
            case "$key" in
                DITTO_DATABASE_ID) ditto_database_id="$value" ;;
                DITTO_SERVER_URL) ditto_server_url="$value" ;;
                DITTO_PLAYGROUND_TOKEN) ditto_playground_token="$value" ;;
            esac
        fi
    done <"$env_file"
fi

cat >"$output_dir/Env.swift" <<EOS
import Foundation

// This file is auto generated. Do not edit this, and edit .env instead.

struct Env {
    static let DITTO_DATABASE_ID = "$ditto_database_id"
    static let DITTO_SERVER_URL = "$ditto_server_url"
    static let DITTO_PLAYGROUND_TOKEN = "$ditto_playground_token"
}
EOS
