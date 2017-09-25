
# Systemd Service Status Check

[![Build Status](https://travis-ci.org/yast/systemd-change-guard.svg?branch=master)](
https://travis-ci.org/yast/systemd-change-guard)

This repository contains a simple script which periodically checks whether
the systemd service introduced a new state.

The reason is that the YaST system services modules migh not work correctly
when a new unhandled stated is added to systemd.

## Details

- The script runs the `systemctl --state=help` command to get the list of states
  from systemd
- The list is compared with the expected states from the `expected_states.yml` file
- If a difference is found then it is printed and the script fails
- The script is running inside [yastdevel/ruby](
  https://hub.docker.com/r/yastdevel/ruby/) Docker image which is based on
  the openSUSE Tumbleweed image and regularly updated (the systemd version in
  the image should be always up to date)
- The script is [configured](https://travis-ci.org/yast/systemd-change-guard/settings)
  to start regularly as a Travis CRON job
