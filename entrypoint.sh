#!/bin/sh

set -e

if [ -z "$SPACE_NAME" ]; then
  echo "SPACE_NAME is not set. Quitting."
  exit 1
fi

if [ -z "$SPACE_REGION" ]; then
  echo "SPACE_REGION is not set. Quitting."
  exit 1
fi

DATACENTERS="nyc1 nyc2 nyc3 ams2 ams3 sfo1 sfo2 sfo3 sgp1 lon1 fra1 tor1 blr1"

if ! echo -n " $DATACENTERS" | grep -q " ${SPACE_REGION} "; then
    echo "WARNING: Unknown datacenter region '$SPACE_REGION'."
    echo "> List of known datacenters: $DATACENTERS"
    exit 1
fi

ENDPOINT="$SPACE_REGION.digitaloceanspaces.com"

if [ -z "$SPACE_ACCESS_KEY" ]; then
  echo "SPACE_ACCESS_KEY is not set. Quitting."
  exit 1
fi

if [ -z "$SPACE_SECRET_KEY" ]; then
  echo "SPACE_SECRET_KEY is not set. Quitting."
  exit 1
fi

if [ -z "$DELETE_UNTRACKED" ] || [ "$DELETE_UNTRACKED" == "true" ]; then
	DELETE_FLAG="--delete-removed"
fi

if [ -z "$SOURCE_DIR" ]; then
  FILES_SOURCE_DIR="./*"
else
  FILES_SOURCE_DIR="./$SOURCE_DIR/"
fi

if [ -z "$FILES_PRIVATE" ] || [ "$FILES_PRIVATE" != "true" ]; then
	ACCESS_FLAG="--acl-public"
else
  ACCESS_FLAG="--acl-private"
fi

if [ -n "$ADD_HEADER" ]; then
  HEADER_FLAG="--recursive --add-header=$ADD_HEADER"
fi

cat >> $HOME/.s3cfg <<CONFIG
access_key = ${SPACE_ACCESS_KEY}
secret_key = ${SPACE_SECRET_KEY}
bucket_location = ${SPACE_REGION}
host_base = ${ENDPOINT}
host_bucket = %(bucket).${ENDPOINT}
CONFIG

s3cmd --no-preserve --no-progress --exclude=".git/*" ${DELETE_FLAG} ${ACCESS_FLAG} ${HEADER_FLAG} sync ${FILES_SOURCE_DIR} s3://${SPACE_NAME}/${SPACE_DIR}
