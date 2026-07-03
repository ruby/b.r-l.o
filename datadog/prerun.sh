#!/usr/bin/env bash
# Sourced by the Datadog Heroku buildpack before starting the agent.
# Dynos cannot create the default socket directory /var/run/datadog, and the
# agent ignores empty values for these settings, so the listeners cannot be
# disabled. Point them at a writable directory instead so they start cleanly.
# The app talks to the agent over TCP 8126 / UDP 8125 either way.
mkdir -p /tmp/datadog
export DD_APM_RECEIVER_SOCKET="/tmp/datadog/apm.socket"
export DD_DOGSTATSD_SOCKET="/tmp/datadog/dsd.socket"

# The buildpack unconditionally re-exports DD_VERSION after sourcing this
# file, turning an unset value into an empty string. The datadog gem then
# builds a "version:" tag that libdatadog rejects with a WARN twice per boot.
# Set the real release version here so unified service tagging works from
# process start.
export DD_VERSION="${DD_VERSION:-$HEROKU_RELEASE_VERSION}"
