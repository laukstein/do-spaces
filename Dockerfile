FROM python:3.10.3-alpine

RUN apk update
RUN apk add tar sed ca-certificates
RUN pip install python-dateutil

ENV AWSCLI_VERSION='1.22.76'

ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS="yes"

RUN pip install --upgrade --quiet --no-cache-dir awscli==${AWSCLI_VERSION}

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
