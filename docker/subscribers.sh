#!/bin/sh
cd /app
sudo -u app -E -- ./bin/notify_subscribers $SUBSCRIBER_INTERVAL
