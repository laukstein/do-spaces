#!/bin/sh

if [ -z "$DO_ACCESS" ]; then
  echo 'DO_ACCESS is not set. Quitting.'
  exit 1
fi

if [ -z "$DO_SECRET" ]; then
  echo 'DO_SECRET is not set. Quitting.'
  exit 1
fi

if [ -z "$DO_NAME" ]; then
  echo 'DO_NAME is not set. Quitting.'
  exit 1
fi

if [ -z "$DO_REGION" ]; then
  echo 'DO_REGION is not set. Quitting.'
  exit 1
fi

if [ -z "$DELETE_UNTRACKED" ] || [ "$DELETE_UNTRACKED" = 'true' ]; then
	DELETE_FLAG='--delete-removed'
fi

if [ -z "$FILES_PRIVATE" ] || [ "$FILES_PRIVATE" != 'true' ]; then
	ACCESS_FLAG='--acl-public'
else
  ACCESS_FLAG='--acl-private'
fi

if [ -n "$ADD_HEADER" ]; then
  HEADER_FLAG="--add-header=$ADD_HEADER"
fi

if [ -z "$LOCAL_DIR" ]; then
  LOCAL_DIR="./"
else
  LOCAL_DIR="$LOCAL_DIR/"
fi

if [ -z "$SPACE_DIR" ]; then
  SPACE_DIR=""
else
  SPACE_DIR="$SPACE_DIR/"
fi

ENDPOINT="$DO_REGION.digitaloceanspaces.com"
cat >> "$HOME/.s3cfg" <<CONFIG
access_key = ${DO_ACCESS}
secret_key = ${DO_SECRET}
bucket_location = ${DO_REGION}
host_base = ${ENDPOINT}
host_bucket = %(bucket).${ENDPOINT}
CONFIG

S3="s3://$DO_NAME/"
UPDATES=$(s3cmd --no-preserve --no-check-md5 --no-progress --recursive --exclude=.git $DELETE_FLAG $ACCESS_FLAG "$HEADER_FLAG" sync $LOCAL_DIR "$S3$SPACE_DIR")
echo 'Changes were successfully updated in DigitalOcean Space'
echo "$UPDATES"

CHANGES=$(echo "$UPDATES" | grep -Po "(?<=${S3})[^']*")

if [ -n "$DO_TOKEN" ] && [ -n "$CHANGES" ]; then
  DO_FILES=''
  for file in ${CHANGES}; do
      CHANGE=${file#"$S3"}
      if [ -n "$DO_FILES" ]; then
        DO_FILES="$DO_FILES,";
      fi
      DO_FILES="$DO_FILES\"$CHANGE\""
  done

  ENDPOINT_ID=$(curl -s -X GET \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $DO_TOKEN" \
    'https://api.digitalocean.com/v2/cdn/endpoints' | jq -r '.endpoints[0].id')

  if [ "$ENDPOINT_ID" != 'null' ]; then
    HTTP_STATUS=$(curl -w "%{http_code}" -o /dev/null -s -X DELETE \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $DO_TOKEN" \
      -d '{"files": ['"$DO_FILES"']}' \
      "https://api.digitalocean.com/v2/cdn/endpoints/$ENDPOINT_ID/cache")

    if [ "$HTTP_STATUS" = '200' ] || [ "$HTTP_STATUS" = '204' ]; then
        echo 'Changes were successfully purged from DigitalOcean CDN'
        echo "$CHANGES"
    else
        echo 'CDN purge failure'
    fi
  else
    echo 'Failed to fetch DigitalOcean endpoints, check your DO_TOKEN'
  fi
fi
