#!/bin/sh
echo "creating crontab"
echo -e "$CRON_SCHEDULE /backup-and-cleanup.sh\n" > /etc/crontabs/root
echo "starting crond"
crond -f