FROM debian:stretch

LABEL maintainer="Uchenna Okafor <uokafor@tradedepot.co>"

RUN sed -i 's|deb.debian.org/debian|archive.debian.org/debian|g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list && \
    apt-get -o Acquire::Check-Valid-Until=false update && \
    apt-get install -y --no-install-recommends ca-certificates openssl curl wget gnupg dirmngr && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt
ENV npm_config_cafile=/etc/ssl/certs/ca-certificates.crt

RUN groupadd -r node && useradd -m -g node node

ENV GOSU_VERSION=1.10

ENV MONGO_VERSION=3.4.10
ENV MONGO_MAJOR=3.4
ENV MONGO_PACKAGE=mongodb-org

ENV PHANTOM_VERSION=2.1.1

ENV APP_SOURCE_DIR=/opt/meteor/src
ENV APP_BUNDLE_DIR=/opt/meteor/dist
ENV BUILD_SCRIPTS_DIR=/opt/build_scripts

COPY scripts $BUILD_SCRIPTS_DIR
RUN chmod -R 750 $BUILD_SCRIPTS_DIR

ONBUILD ARG APT_GET_INSTALL
ONBUILD ENV APT_GET_INSTALL=$APT_GET_INSTALL

ONBUILD ARG NODE_VERSION
ONBUILD ENV NODE_VERSION=${NODE_VERSION:-12.14.1}

ONBUILD ARG NPM_TOKEN
ONBUILD ENV NPM_TOKEN=$NPM_TOKEN

ONBUILD ARG INSTALL_MONGO
ONBUILD ENV INSTALL_MONGO=$INSTALL_MONGO

ONBUILD ARG INSTALL_PHANTOMJS
ONBUILD ENV INSTALL_PHANTOMJS=$INSTALL_PHANTOMJS

ONBUILD ARG INSTALL_GRAPHICSMAGICK
ONBUILD ENV INSTALL_GRAPHICSMAGICK=$INSTALL_GRAPHICSMAGICK

ONBUILD ARG TOOL_NODE_FLAGS
ONBUILD ENV TOOL_NODE_FLAGS=$TOOL_NODE_FLAGS

ONBUILD ARG NODE_OPTIONS
ONBUILD ENV NODE_OPTIONS=$NODE_OPTIONS

ONBUILD RUN sed -i 's|deb.debian.org/debian|archive.debian.org/debian|g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list && \
    apt-get -o Acquire::Check-Valid-Until=false update && \
    apt-get install -y --no-install-recommends ca-certificates openssl curl && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

ONBUILD RUN if [ "$APT_GET_INSTALL" ]; then \
    apt-get -o Acquire::Check-Valid-Until=false update && \
    apt-get install -y --no-install-recommends $APT_GET_INSTALL && \
    rm -rf /var/lib/apt/lists/*; \
  fi

ONBUILD COPY . $APP_SOURCE_DIR

ONBUILD RUN cd $APP_SOURCE_DIR && \
  $BUILD_SCRIPTS_DIR/install-deps.sh && \
  $BUILD_SCRIPTS_DIR/install-node.sh && \
  $BUILD_SCRIPTS_DIR/install-phantom.sh && \
  $BUILD_SCRIPTS_DIR/install-graphicsmagick.sh && \
  $BUILD_SCRIPTS_DIR/install-mongo.sh && \
  $BUILD_SCRIPTS_DIR/install-meteor.sh && \
  $BUILD_SCRIPTS_DIR/build-meteor.sh && \
  $BUILD_SCRIPTS_DIR/post-build-cleanup.sh

ENV ROOT_URL=http://localhost
ENV MONGO_URL=mongodb://127.0.0.1:27017/meteor
ENV PORT=3000

EXPOSE 3000

WORKDIR $APP_BUNDLE_DIR/bundle

ENTRYPOINT ["./entrypoint.sh"]
CMD ["node", "main.js"]
