#!/bin/sh -e

#check that the backup location directory has been specified
if [[ -z ${BACKUP_SOURCE_DIR} ]];
then
    echo "The source directory location of the backup must be set in BACKUP_SOURCE_DIR. Exiting."
    return 0
fi

if [[ -z ${FILE_EXTENSION} ]];
then
    echo "The file extension type must be set in FILE_EXTENSION. Exiting"
    return 0
fi

if [[ -z ${S3_BUCKET_URL} ]];
then
    echo "The s3 bucket url must be set in S3_BUCKET_URL. Exiting"
    return 0
fi

#try to find the target backup name. gets the most recent modified .zip file in the specified backup directory
echo "Trying to find most recent backup with file type .$FILE_EXTENSION in directory $BACKUP_SOURCE_DIR"
TARGET=$(ls -Art ${BACKUP_SOURCE_DIR} | grep ".${FILE_EXTENSION}$" | tail -n 1)
if [[ -z ${TARGET} ]]; then
    echo "A target backup of file type .$FILE_EXTENSION could not be found in directory $BACKUP_SOURCE_DIR. Exiting."
    return 0
else
    echo "Target backup found: $BACKUP_SOURCE_DIR/$TARGET"
fi

echo "Uploading backup to S3..."
aws s3 cp $BACKUP_SOURCE_DIR/$TARGET $S3_BUCKET_URL

if [[ $? = "0" ]]; then
    echo "Upload successful"

    if [[ -n ${WEBHOOK} ]];
    then
        echo "Pinging $WEBHOOK"
        curl -i -s -m 10 --retry 5 -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"S3 backup successful.\"}" $WEBHOOK
    fi
else
    echo "Upload unsuccessful, code $?"

    if [[ -n ${WEBHOOK} ]];
    then
        echo "Pinging $WEBHOOK"
        curl -i -s -m 10 --retry 5 -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"S3 backup unsuccessful. Error $?.\"}" $WEBHOOK
    fi

    return 0
fi


if [[ ${CLEAR_BACKUPS} = true ]];
then
    echo "Clearing $BACKUP_SOURCE_DIR of all files of type .$FILE_EXTENSION"
    rm -rf $BACKUP_SOURCE_DIR/*.$FILE_EXTENSION
fi
