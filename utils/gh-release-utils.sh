#!/usr/bin/env bash

# Utils for fetching release assets from GitHub
# Use the vendored JQ for this script
JQ="jq-vendor"

curl_api() {
  API_URL="$1"
  FULL_URL="https://api.github.com/${API_URL}"
  curl -s -H "Accept: application/vnd.github.v3+json" "${FULL_URL}"
}

jq_filt() {
  JSON_BLOB="$1"
  JQ_FILTER="$2"
  echo "${JSON_BLOB}" | $JQ -c "${JQ_FILTER}"
}

get_latest_release_assets() {
  USER_REPO_PATH="$1"
  curl_api "repos/${USER_REPO_PATH}/releases?per_page=1&page=1"
}

get_latest_release_file() {
  USER_REPO_PATH="$1"
  FILE_NAME_MATCHER="$2"
  LATEST_RELEASE_ASSETS=$(get_latest_release_assets "${USER_REPO_PATH}")
  while IFS= read -r OBJ; do
    FILE_NAME="$(jq_filt "${OBJ}" '.name' | tr -d \")"
    if [[ "${FILE_NAME}" =~ .*"${FILE_NAME_MATCHER}".* ]]; then
      echo "$(jq_filt "${OBJ}" '.browser_download_url' | tr -d \")"
      break
    fi
  done < <(jq_filt "${LATEST_RELEASE_ASSETS}" '.[0].assets[]')
}

download_release() {
  USER_REPO_PATH="$1"
  FILE_NAME_MATCHER="$2"
  OUTPUT_FILE=$3
  curl -s -o "${OUTPUT_FILE}" -L "$(get_latest_release_file "${USER_REPO_PATH}" "${FILE_NAME_MATCHER}")"
}
