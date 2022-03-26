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

if [ -n "$ADD_HEADER" ]; then
  HEADER_FLAG="--add-header $ADD_HEADER"
fi

s3cmd sync ${SOURCE_DIR:-.} s3://${SPACE_NAME}/${SPACE_DIR} \
  --access_key=${SPACE_ACCESS_KEY} \
  --secret_key=${SPACE_SECRET_KEY} \
  --region=${SPACE_REGION} \
  --acl-public \
  --no-preserve \
  --no-progress \
  --follow-symlinks \
  --exclude=".git/*" \
  ${DELETE_FLAG} \
  ${HEADER_FLAG}
