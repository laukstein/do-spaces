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

if [ -n "$CF_TOKEN" ] && [ -z "$CF_ZONE" ]; then
  echo 'CF_ZONE is not set. Skipping purge Cloudflare cache.'
fi
if [ -n "$CF_ZONE" ] && [ -z "$CF_TOKEN" ]; then
  echo 'CF_TOKEN is not set. Skipping purge Cloudflare cache.'
fi
if [ -n "$CF_TOKEN" ] && [ -n "$CF_ZONE" ] && [ -n "$CF_URL" ]; then
  CF_ENABLED='true'
fi

if [ -z "$DELETE_UNTRACKED" ] || [ "$DELETE_UNTRACKED" = 'true' ]; then
	DELETE_FLAG='--delete-removed'
fi

if [ -z "$FILES_PRIVATE" ] || [ "$FILES_PRIVATE" != 'true' ]; then
	ACCESS_FLAG='--acl-public'
else
  ACCESS_FLAG='--acl-private'
fi

if [ -z "$ADD_HEADER" ]; then
  HEADER_FLAG=""
else
  HEADER_FLAG="--add-header=$ADD_HEADER"
fi

if [ -z "$LOCAL_DIR" ]; then
  LOCAL_DIR="./"
else
  LOCAL_DIR="$LOCAL_DIR/"
fi

if [ -z "$DO_DIR" ]; then
  DO_DIR=""
else
  DO_DIR="$DO_DIR/"
fi

if [ -n "$CF_URL" ] && [ "${CF_URL:-1}" != '/' ]; then
  CF_URL="$CF_URL/"
else
  CF_URL='/'
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
UPDATES=$(s3cmd --no-preserve --no-check-md5 --no-progress --recursive --exclude=.git $DELETE_FLAG $ACCESS_FLAG $HEADER_FLAG sync $LOCAL_DIR $S3$DO_DIR)
DO_FILES=''
CF_URLS=''
echo 'Changes successfully updated in DigitalOcean Space:'
echo "$UPDATES"


CHANGES=$(echo "$UPDATES" | grep -Po "(?<=${S3})[^']*")
URLS=''

for file in ${CHANGES}; do
    CHANGE=${file#"$S3"}

    if [ -n "$DO_FILES" ]; then
      DO_FILES="$DO_FILES,"
    fi
    if [ -n "$CF_URLS" ]; then
      CF_URLS="$CF_URLS,"
      URLS="$URLS\n"
    fi

    DO_FILES="$DO_FILES\"$CHANGE\""
    CF_URLS="$CF_URLS\"$CF_URL$CHANGE\""
    URLS="$URLS$CF_URL$CHANGE"
done

if [ -n "$DO_TOKEN" ]; then
  HTTP_RESPONSE=$(curl -sS -X GET \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $DO_TOKEN" \
    -w "HTTP_STATUS:%{http_code}" \
    'https://api.digitalocean.com/v2/cdn/endpoints')
  HTTP_STATUS=$(echo "${HTTP_RESPONSE}" | tr -d '\n' | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')
  HTTP_BODY=$(echo "${HTTP_RESPONSE}" | sed -E 's/HTTP_STATUS\:[0-9]{3}$//')
  ENDPOINT_ID=$(echo "$HTTP_BODY" | jq -r '.endpoints[0].id')

  if [ "$ENDPOINT_ID" != 'null' ]; then
    HTTP_RESPONSE=$(curl -sS -X DELETE \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $DO_TOKEN" \
      -d '{"files": ['"$DO_FILES"']}' \
      -w "HTTP_STATUS:%{http_code}" \
      "https://api.digitalocean.com/v2/cdn/endpoints/$ENDPOINT_ID/cache")
    HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tr -d '\n' | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')
    HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed -E 's/HTTP_STATUS\:[0-9]{3}$//')

    if [ "$HTTP_STATUS" = '200' ] || [ "$HTTP_STATUS" = '204' ]; then
        echo 'Changes successfully purged from DigitalOcean CDN:'
        echo "$CHANGES"

        if [ -z "$CF_ENABLED" ]; then
          exit 0
        fi
    else
        echo 'DigitalOcean CDN purge failed. API response:'
        echo "$HTTP_BODY"
    fi
  else
    echo 'Failed to fetch DigitalOcean endpoints. API response:'
    echo "$HTTP_BODY"
  fi
  if [ -z "$CF_ENABLED" ]; then
    exit 1
  fi
fi


if [ -n "$CF_ENABLED" ]; then
  HTTP_RESPONSE=$(curl -sS -X POST \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $CF_TOKEN" \
      --data '{"files": ['"$CF_URLS"']}' \
      -w "HTTP_STATUS:%{http_code}" \
      "https://api.cloudflare.com/client/v4/zones/$CF_ZONE/purge_cache")
  HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tr -d '\n' | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')
  HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed -E 's/HTTP_STATUS\:[0-9]{3}$//')

  if [ "$HTTP_STATUS" = '200' ]; then
     echo 'Changes successfully purged from Cloudflare cache:'
     printf "$URLS"
     exit 0
  else
     echo 'Cloudflare cache purge failed. API response:'
     echo "$HTTP_BODY"
     exit 1
  fi
fi
