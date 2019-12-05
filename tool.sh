#!/usr/bin/env bash

if [ -f /.codacyrc ]; then
  #parse
  codacyrc_file=$(jq -erM '.' < /.codacyrc)

  # error on invalid json
  if [ $? -ne 0 ]; then
    echo "Can't parse .codacyrc file"
    exit 1
  fi

  codacy_files=$(jq -cer '.files | .[]' <<< "$codacyrc_file")

  codacy_lang=$(jq -cer '.language' <<< "$codacyrc_file")
  if [ "$(echo "$codacy_lang" | tr '[:upper:]' '[:lower:]')" != "shell" ]; then
    echo "Language is not supported (only 'Shell' available)"
    exit 1
  fi
else
  codacy_files=$(cd /src || exit; find . -type f -exec echo {} \; | cut -c3-)
fi

function report_error {
  local file="$1"
  local lines="$2"
  echo "{\"filename\":\"$file\",\"complexity\": 1,\"loc\": $lines,\"cloc\": 0,\"nrMethods\":1,\"nrClasses\":1,\"lineComplexities\":[]}"
}

function analyze_file {
  local file="$1"
  final_file="/src/$file"
  if [ -f "$final_file" ]; then
    report_error "$file" "$(wc -l < "$final_file")"
  else
    echo "{\"filename\":\"$final_file\",\"message\":\"could not parse the file\"}"
  fi
}

while read -r file; do
  analyze_file "$file"
done <<< "$codacy_files"
