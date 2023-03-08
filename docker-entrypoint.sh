#!/bin/sh

#read in the aws access key information
if [[ -n ${AWS_ACCESS_KEY_ID_FILE} ]];
then
    export AWS_ACCESS_KEY_ID=$(cat $AWS_ACCESS_KEY_ID_FILE)
fi

if [[ -n ${AWS_SECRET_ACCESS_KEY_FILE} ]];
then
    export AWS_SECRET_ACCESS_KEY=$(cat $AWS_SECRET_ACCESS_KEY_FILE)
fi

#cron job
echo "creating crontab"
echo -e "$CRON_SCHEDULE /backup-and-cleanup.sh\n" > /etc/crontabs/root
echo "starting crond"
crond -f