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

if [ -z "$FILES_PRIVATE" ] || [ "$FILES_PRIVATE" != "true" ]; then
	ACCESS_FLAG="--acl-public"
else
  ACCESS_FLAG="--acl-private"
fi

if [ -n "$ADD_HEADER" ]; then
  HEADER_FLAG="--add-header $ADD_HEADER"
fi

sed -e "s|\[\[access_key\]\]|${SPACE_ACCESS_KEY}|" -e "s|\[\[secret_key\]\]|${SPACE_SECRET_KEY}|" -e "s|\[\[region\]\]|${SPACE_REGION}|" /root/.s3cfg.temp > /github/home/.s3cfg

s3cmd sync ${SOURCE_DIR:-.} s3://${SPACE_NAME}/${SPACE_DIR} \
  ${ACCESS_FLAG} \
  --no-preserve \
  --no-progress \
  --follow-symlinks \
  --exclude=".git/*" \
  ${DELETE_FLAG} \
  ${HEADER_FLAG} \
  --ssl \
  --host=${ENDPOINT} \
  --host-bucket=%(bucket)s.${ENDPOINT}
