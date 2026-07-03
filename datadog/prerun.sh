#!/usr/bin/env bash
# Sourced by the Datadog Heroku buildpack before starting the agent.
# Dynos cannot create /var/run/datadog; disable the UDS listeners
# (TCP 8126 / UDP 8125 are used instead).
export DD_APM_RECEIVER_SOCKET=""
export DD_DOGSTATSD_SOCKET=""
