#!/bin/sh -e

for REMOTE_TARGET in "$@"; do
    FOUND=$(aws s3 ls $S3_BUCKET_URL | awk '{print $4}' | grep "$REMOTE_TARGET")
    if [[ -z $FOUND ]];
    then
        exit 1
    fi
done

echo "All files present on s3"