#!/bin/sh

set -e

if [ -z "$DO_ACCESS" ]; then
  echo "DO_ACCESS is not set. Quitting."
  exit 1
fi

if [ -z "$DO_SECRET" ]; then
  echo "DO_SECRET is not set. Quitting."
  exit 1
fi

if [ -z "$DO_NAME" ]; then
  echo "DO_NAME is not set. Quitting."
  exit 1
fi

if [ -z "$DO_REGION" ]; then
  echo "DO_REGION is not set. Quitting."
  exit 1
fi

DATACENTERS="nyc1 nyc2 nyc3 ams2 ams3 sfo1 sfo2 sfo3 sgp1 lon1 fra1 tor1 blr1"

if ! echo -n " $DATACENTERS" | grep -q " ${DO_REGION} "; then
    echo "WARNING: Unknown datacenter region '$DO_REGION'."
    echo "> List of known datacenters: $DATACENTERS"
    exit 1
fi

ENDPOINT="$DO_REGION.digitaloceanspaces.com"

if [ -z "$DELETE_UNTRACKED" ] || [ "$DELETE_UNTRACKED" == "true" ]; then
	DELETE_FLAG="--delete-removed"
fi

if [ -z "$FILES_PRIVATE" ] || [ "$FILES_PRIVATE" != "true" ]; then
	ACCESS_FLAG="--acl-public"
else
  ACCESS_FLAG="--acl-private"
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

cat >> $HOME/.s3cfg <<CONFIG
access_key = ${DO_ACCESS}
secret_key = ${DO_SECRET}
bucket_location = ${DO_REGION}
host_base = ${ENDPOINT}
host_bucket = %(bucket).${ENDPOINT}
CONFIG

# Update changes in DigitalOcean Space
s3cmd --no-preserve --no-check-md5 --no-progress --recursive --exclude=.git ${DELETE_FLAG} ${ACCESS_FLAG} ${HEADER_FLAG} sync ${LOCAL_DIR} s3://${DO_NAME}/${SPACE_DIR}


# Purge changes from DigitalOcean CDN
if [ -n "$DO_TOKEN" ]; then
  if [ -z "$CHANGES" ]; then
    echo "Missing CHANGES to purge CDN cache."
    exit 1
  fi
fi
if [ -n "$CHANGES" ]; then
  if [ -z "$DO_TOKEN" ]; then
    echo "Missing DO_TOKEN to purge CDN cache."
    exit 1
  fi

  DO_FILES=""
  REMOVE_PATH=${LOCAL_DIR//.\/}
  for file in ${CHANGES}; do
      [ -n "$DO_FILES" ] && DO_FILES+=", "
      DO_FILES+="\"${file#"$REMOVE_PATH"}\""
  done

  if [ -n "$DO_FILES" ]; then
    DO_FILES="[$DO_FILES]"

    ENDPOINTS=`curl --request GET \
      --header "Content-Type: application/json" \
      --header "Authorization: Bearer $DO_TOKEN" \
      --url "https://api.digitalocean.com/v2/cdn/endpoints"`

    if [ -n "$ENDPOINTS" ]; then
      DO_CDN_ID=${{ fromJSON($ENDPOINTS).endpoints[0].id }}

      if [ -n "$DO_CDN_ID" ]; then
        RESPONSE=`curl --write-out '%{http_code}' \
          --silent \
          --output /dev/null \
          --request DELETE \
          --header "Content-Type: application/json" \
          --header "Authorization: Bearer $DO_TOKEN" \
          --url "https://api.digitalocean.com/v2/cdn/endpoints/$DO_CDN_ID/cache" \
          --data '{"files": $DO_FILES}'`

        if [ $RESPONSE == "200" ]; then
            echo "CDN purge success"
        else
            echo "CDN purge failure"
        fi
      fi
    fi
  fi
fi
