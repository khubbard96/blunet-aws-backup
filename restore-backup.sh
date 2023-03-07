#!/bin/sh -e

#check args
if [[ -z ${1} ]];
then
    echo "First arg must be the name of the backup on s3. Exiting."
    return 0
fi

if [[ -z ${BACKUP_TARGET_DIR} ]];
then
    echo "The target local directory for the backup must be set in BACKUP_TARGET_DIR. Exiting."
    return 0
fi

if [[ -z ${S3_BUCKET_URL} ]];
then
    echo "The s3 bucket url must be set in S3_BUCKET_URL. Exiting"
    return 0
fi

#pull backup from s3
echo "Searching for ${1} in $S3_BUCKET_URL"
S3_TARGET=$(aws s3 ls $S3_BUCKET_URL | awk '{print $4}' | grep "${1}")
if [[ -n ${S3_TARGET} ]];
then
    echo "Target backup found on s3: ${1}"
else
    echo "No backup matching ${1} was found in s3 bucket $S3_BUCKET_URL. Exiting."
    return 0
fi

echo "Copying backup from s3"
aws s3 cp $S3_BUCKET_URL/$S3_TARGET /${1}

if [[ $? = "0" ]]; then
    echo "s3 pull successful"
else
    echo "s3 pull unsuccessful with code $?. Exiting."
    return 0
fi

LOCAL_TARGET=$(find / -type d -path "$BACKUP_TARGET_DIR")
if [[ -z ${LOCAL_TARGET} ]];
then
    echo "No directory matching the path $BACKUP_TARGET_DIR was found on local. Exiting."
    return 0
fi

echo "Matching local target directory found."

echo "Loading backup into $BACKUP_TARGET_DIR. Existing files and directories will be overwritten"

unzip -o /${1} -d $BACKUP_TARGET_DIR

echo "Backup restored on local target"


#ping webhook with some data
if [[ -n ${WEBHOOK} ]];
then
    echo "Pinging $WEBHOOK"
    curl -i -s -m 10 --retry 5 -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"A backup from s3 was restored: ${1}.\"}" $WEBHOOK    
fi