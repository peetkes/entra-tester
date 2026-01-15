#!/bin/bash

set -e

if [[ -z "$1" ]]; then
  echo "Usage: $0 <jwt-token>"
  exit 1
fi

decode_segment() {
  local segment=$1
  local rem=$(( ${#segment} % 4 ))
  if [ $rem -eq 2 ]; then segment="${segment}=="
  elif [ $rem -eq 3 ]; then segment="${segment}="
  elif [ $rem -eq 1 ]; then segment="${segment}==="
  fi
  echo "$segment" | tr '_-' '/+' | base64 -d 2>/dev/null
}

IFS='.' read -r HEADER PAYLOAD SIGNATURE <<< "$1"

if [[ -z "$HEADER" || -z "$PAYLOAD" ]]; then
  echo "❌ Invalid JWT: must have at least 2 parts (header.payload)."
  exit 1
fi

echo "🔐 JWT Header:"
decode_segment "$HEADER" | jq .

echo
echo "📦 JWT Payload:"
decode_segment "$PAYLOAD" | jq .

echo
echo "✍️ Signature (not decoded):"
echo "$SIGNATURE"