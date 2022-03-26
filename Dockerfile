FROM python:3.8-alpine

LABEL "com.github.actions.name"="DigitalOcean Spaces Sync"
LABEL "com.github.actions.description"="Sync assets to repository-specific directory within space, maintaining local directory structure"
LABEL "com.github.actions.icon"="refresh-cw"
LABEL "com.github.actions.color"="green"
LABEL version="0.0.1"
LABEL repository="https://github.com/laukstein/do-spaces"
LABEL homepage="https://laukstein.com/"
LABEL maintainer="Binyamin Laukstein <https://laukstein.com>"

RUN apk update
RUN apk add tar sed ca-certificates
RUN pip install python-dateutil

ENV AWSCLI_VERSION='1.18.14'

RUN pip install --quiet --no-cache-dir awscli==${AWSCLI_VERSION}

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
