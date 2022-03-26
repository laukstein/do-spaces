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

if [ -z "$DELETE_UNTRACKED" || "$DELETE_UNTRACKED" == "true" ]; then
	DELETE_FLAG="--delete"
fi

if [ -n "$ADD_HEADER" ]; then
  HEADER_FLAG="--add-header $ADD_HEADER"
fi

aws configure --profile s3-sync-action <<-EOF > /dev/null 2>&1
${SPACE_ACCESS_KEY}
${SPACE_SECRET_KEY}
${SPACE_REGION}
text
EOF

sh -c "aws s3 sync ${SOURCE_DIR:-.} s3://${SPACE_NAME}/${SPACE_DIR} \
              --profile s3-sync-action \
              --no-progress \
              ${DELETE_FLAG} \
              ${HEADER_FLAG} \
              --endpoint-url https://${SPACE_REGION}.digitaloceanspaces.com $*"

aws configure --profile s3-sync-action <<-EOF > /dev/null 2>&1
null
null
null
text
EOF
