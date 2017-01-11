FROM alpine:3.4
MAINTAINER Aleksei Pavliukov <alex@implus.co>

ENV GOSU_VERSION 1.9
ENV PGWEB_VERSION v0.9.6
ENV PGWEB_ZIP_SHA256 550fb4bc628b51891a5fd5cfd48221999154343d0c2a9a4182b4151ff8464fe6

RUN set -x \
    && apk add --no-cache --virtual .gosu-deps \
        dpkg \
        gnupg \
        openssl \
        unzip \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && wget -O /tmp/pgweb.zip "https://github.com/sosedoff/pgweb/releases/download/$PGWEB_VERSION/pgweb_linux_amd64.zip" \
    && echo "${PGWEB_ZIP_SHA256}  /tmp/pgweb.zip" > /tmp/pgweb.sha256 \
    && sha256sum -c /tmp/pgweb.sha256 \
    && apk del .gosu-deps unzip

RUN addgroup pgweb && \
    adduser -S -G pgweb pgweb

RUN mkdir /app
WORKDIR /app

RUN unzip /tmp/pgweb.zip -d /app \
    && rm /tmp/pgweb.zip \
    && chmod +x /app/pgweb_linux_amd64

EXPOSE 8081

ENTRYPOINT ["gosu"]
CMD ["pgweb", "/app/pgweb_linux_amd64", "--sessions", "--bind", "0.0.0.0"]

#ENTRYPOINT ["/app/pgweb_linux_amd64"]
#CMD ["--sessions"]
