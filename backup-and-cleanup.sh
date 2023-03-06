#!/bin/sh -e

#check that the backup location directory has been specified
if [[ -z ${BACKUP_DIR} ]];
then
    echo "The directory location of the backup must be set in BACKUP_DIR. Exiting."
    return 0
fi

if [[ -z ${FILE_EXTENSION} ]];
then
    echo "The file extension type must be set in FILE_EXTENSION. Exiting"
    return 0
fi

#try to find the target backup name. gets the most recent modified .zip file in the specified backup directory
TARGET=$(ls -Art ${BACKUP_DIR} | grep ".${FILE_EXTENSION}$" | tail -n 1)
if [[ -z ${TARGET} ]]; then
    echo "A target backup of file type .$FILE_EXTENSION could not be found in directory $BACKUP_DIR. Exiting."
    return 0
else
    echo "Target backup found: $BACKUP_DIR/$TARGET"
fi

echo "Uploading backup to S3..."
aws s3 cp $BACKUP_DIR/$TARGET $S3_BUCKET_URL
echo "done"

if [[ ${CLEAR_BACKUPS} = "true" ]];
then
    echo "Clearing $BACKUP_DIR of all files of type .$FILE_EXTENSION"
    rm -rf $BACKUP_DIR/*.$FILE_EXTENSION
fi
