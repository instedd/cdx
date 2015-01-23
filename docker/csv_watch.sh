#!/bin/sh
cd /app
sudo -u app -E -- bundle exec rake csv:watch
