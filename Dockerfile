FROM python:3.10.4-alpine

ADD .s3cfg /.s3cfg
ADD entrypoint.sh /entrypoint.sh

RUN apk add --update bash libmagic && \
    pip install --quiet --no-cache-dir s3cmd python-dateutil python-magic && \
    ln -s /.s3cfg /root/.s3cfg


ENTRYPOINT ["/entrypoint.sh"]
