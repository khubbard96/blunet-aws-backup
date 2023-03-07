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

if [[ -z ${NUM_MOST_RECENT_FILES} ]];
then
    NUM_MOST_RECENT_FILES=1
fi

#try to find the target backup name. gets the most recent modified .zip file in the specified backup directory
echo "Trying to find $NUM_MOST_RECENT_FILES most recent backup(s) with file type .$FILE_EXTENSION in directory $BACKUP_SOURCE_DIR"
TARGETS=$(ls -Art ${BACKUP_SOURCE_DIR} | grep ".${FILE_EXTENSION}$" | tail -n $NUM_MOST_RECENT_FILES)
UPLOAD_STATES='```\n'
if [[ -z ${TARGETS} ]]; then
    echo "A target backup of file type .$FILE_EXTENSION could not be found in directory $BACKUP_SOURCE_DIR. Exiting."
    return 0
else
    for TARGET in $(ls -Art ${BACKUP_SOURCE_DIR} | grep ".${FILE_EXTENSION}$" | tail -n $NUM_MOST_RECENT_FILES)
    do
        echo "Target backup found: $BACKUP_SOURCE_DIR/$TARGET"
        echo "Uploading backup to S3..."
        aws s3 cp $BACKUP_SOURCE_DIR/$TARGET $S3_BUCKET_URL

        if [[ $? = "0" ]]; then
            echo "Upload successful"

            UPLOAD_STATES="$UPLOAD_STATES$TARGET\\t SUCCESS\\n"
        else
            echo "Upload unsuccessful, code $?"
            UPLOAD_STATES="$UPLOAD_STATES$TARGET\\t UNSUCCESSFUL\\n"
        fi
    done
fi


UPLOAD_STATES=$UPLOAD_STATES'```'

echo $UPLOAD_STATES

if [[ -n ${WEBHOOK} ]];
then
    echo "Pinging $WEBHOOK"
    echo "{\"content\": \"S3 backup initiated:$UPLOAD_STATES\"}"
    curl -i -s -m 10 --retry 5 -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"S3 backup initiated:$UPLOAD_STATES\"}" $WEBHOOK
fi


if [[ ${CLEAR_BACKUPS} = true ]];
then
    echo "Clearing $BACKUP_SOURCE_DIR of all files of type .$FILE_EXTENSION"
    rm -rf $BACKUP_SOURCE_DIR/*.$FILE_EXTENSION
fi
