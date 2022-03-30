#!/bin/sh

set -e

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

# Update changes in DigitalOcean Space
s3cmd --no-preserve --no-check-md5 --no-progress --recursive --exclude=.git ${DELETE_FLAG} ${ACCESS_FLAG} "$HEADER_FLAG" sync ${LOCAL_DIR} "s3://$DO_NAME/$SPACE_DIR"


# Purge changes from DigitalOcean CDN
if [ -n "$DO_TOKEN" ]; then
  if [ -z "$CHANGES" ]; then
    echo 'Missing CHANGES to purge CDN cache.'
    exit 1
  fi
fi
if [ -n "$CHANGES" ]; then
  if [ -z "$DO_TOKEN" ]; then
    echo 'Missing DO_TOKEN to purge CDN cache.'
    exit 1
  fi

  DO_FILES=''
  REMOVE_PATH=${LOCAL_DIR#./}
  for file in ${CHANGES}; do
      if [ -n "$DO_FILES" ]; then
        DO_FILES="$DO_FILES,";
      fi
      DO_FILES="$DO_FILES\"${file#"$REMOVE_PATH"}\""
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
        echo 'CDN purge success'
    else
        echo 'CDN purge failure'
    fi
  else
    echo 'Failed to fetch DigitalOcean endpoints, check your DO_TOKEN'
  fi
fi
