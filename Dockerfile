FROM python:3.10.4-alpine

RUN apk add --update bash libmagic && \
    pip install --quiet --no-cache-dir s3cmd python-dateutil python-magic

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
