#!/usr/bin/env bash
# Sourced by the Datadog Heroku buildpack before starting the agent.
# Dynos cannot create /var/run/datadog; disable the UDS listeners
# (TCP 8126 / UDP 8125 are used instead).
export DD_APM_RECEIVER_SOCKET=""
export DD_DOGSTATSD_SOCKET=""

# The buildpack unconditionally re-exports DD_VERSION after sourcing this
# file, turning an unset value into an empty string. The datadog gem then
# builds a "version:" tag that libdatadog rejects with a WARN twice per boot.
# Set the real release version here so unified service tagging works from
# process start.
export DD_VERSION="${DD_VERSION:-$HEROKU_RELEASE_VERSION}"
