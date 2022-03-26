FROM python:3.8-alpine

RUN apk add --update bash libmagic && \
    python -m pip install --quiet --no-cache-dir s3cmd python-dateutil python-magic

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
