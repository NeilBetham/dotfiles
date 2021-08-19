#!/usr/bin/env bash

# Utils for fetching release assets from GitHub

function log_error() {
  MESSAGE="$1"
  echo "[ERROR] - ${MESSAGE}"
}

function cmd_exists() {
  command -v "$1" &> /dev/null
}

function curl_wrap() {
  URI="$1"
  HEADERS="$2"
  OUTPUT_FILE="$3"

  if [ -z "${HEADERS}" ]; then
    if [ -z "${OUTPUT_FILE}" ]; then
      curl -sL "${URI}"
    else
      curl -sL -o "${OUTPUT_FILE}" "${URI}"
    fi
  else
    if [ -z "${OUTPUT_FILE}" ]; then
      curl -sL -H "${HEADERS}" "${URI}"
    else
      curl -sL -H "${HEADERS}" -o "${OUTPUT_FILE}" "${URI}"
    fi
  fi
}

function wget_wrap() {
  URI="$1"
  HEADERS="$2"
  OUTPUT_FILE="$3"

  if [ -z "${HEADERS}" ]; then
    if [ -z "${OUTPUT_FILE}" ]; then
      wget -q "${URI}" -O -
    else
      wget -q -O "${OUTPUT_FILE}" "${URI}"
    fi
  else
    if [ -z "${OUTPUT_FILE}" ]; then
      wget -q --header "${HEADERS}" "${URI}" -O -
    else
      wget -q --header "${HEADERS}" -O "${OUTPUT_FILE}" "${URI}"
    fi
  fi
}

function http_download() {
  URI="$1"
  HEADERS="$2"
  OUTPUT_FILE="$3"

  if cmd_exists curl; then
    curl_wrap "${URI}" "${HEADERS}" "${OUTPUT_FILE}"
    return
  elif cmd_exists wget; then
    wget_wrap "${URI}" "${HEADERS}" "${OUTPUT_FILE}"
    return
  fi
  log_error "No valid http download tool"
  return 1
}

function call_gh_api() {
  API_URL="$1"
  FULL_URL="https://api.github.com/${API_URL}"
  http_download "${FULL_URL}" "Accept: application/vnd.github.v3+json"
}

function filter_json_for_assets() {
  RELEASES_JSON="$1"
  echo "${RELEASES_JSON}" \
    | tr -s '\n' ' ' \
    | sed 's/.*"assets"//' \
    | sed 's/browser/\nbrowser/g' \
    | grep browser \
    | sed 's/browser_download_url": "//' \
    | sed 's/".*//' \
    | tr -s '\n' ' '
}

function get_latest_release_assets() {
  USER_REPO_PATH="$1"
  call_gh_api "repos/${USER_REPO_PATH}/releases?per_page=1&page=1"
}

function get_latest_release_file() {
  USER_REPO_PATH="$1"
  FILE_NAME_MATCHER="$2"
  LATEST_RELEASE_ASSETS=$(get_latest_release_assets "${USER_REPO_PATH}")
  ASSERT_URLS=($(filter_json_for_assets "${LATEST_RELEASE_ASSETS}"))
  for ASSET_URL in "${ASSERT_URLS[@]}"; do
    if [[ ${ASSET_URL} =~ ${FILE_NAME_MATCHER} ]]; then
      echo "${ASSET_URL}"
      break
    fi
  done
}

function download_release() {
  USER_REPO_PATH="$1"
  FILE_NAME_MATCHER="$2"
  OUTPUT_FILE=$3
  http_download "$(get_latest_release_file "${USER_REPO_PATH}" "${FILE_NAME_MATCHER}")" "" "${OUTPUT_FILE}"
}
