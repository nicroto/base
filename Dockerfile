FROM debian:jessie
MAINTAINER Reaction Commerce <admin@reactioncommerce.com>

RUN groupadd -r node && useradd -m -g node node

# Gosu
ENV GOSU_VERSION 1.10

# MongoDB
ENV MONGO_VERSION 3.4.4
ENV MONGO_MAJOR 3.4
ENV MONGO_PACKAGE mongodb-org

# PhantomJS
ENV PHANTOM_VERSION 2.1.1

# provide a way to detect if we're inside
# an official Reaction Docker build
ENV REACTION_DOCKER_BUILD true

# build directories
ENV APP_SOURCE_DIR /opt/reaction/src
ENV APP_BUNDLE_DIR /opt/reaction/dist
ENV BUILD_SCRIPTS_DIR /opt/build_scripts

# Add entrypoint and build scripts
COPY scripts $BUILD_SCRIPTS_DIR
RUN chmod -R 750 $BUILD_SCRIPTS_DIR

# Define all --build-arg options
ONBUILD ARG APT_GET_INSTALL
ONBUILD ENV APT_GET_INSTALL $APT_GET_INSTALL

ONBUILD ARG NODE_VERSION
ONBUILD ENV NODE_VERSION ${NODE_VERSION:-4.8.3}

ONBUILD ARG INSTALL_MONGO
ONBUILD ENV INSTALL_MONGO $INSTALL_MONGO

ONBUILD ARG INSTALL_PHANTOMJS
ONBUILD ENV INSTALL_PHANTOMJS $INSTALL_PHANTOMJS

# Node flags for the Meteor build tool
ONBUILD ARG TOOL_NODE_FLAGS
ONBUILD ENV TOOL_NODE_FLAGS $TOOL_NODE_FLAGS

# optionally custom apt dependencies at app build time
ONBUILD RUN if [ "$APT_GET_INSTALL" ]; then apt-get update && apt-get install -y $APT_GET_INSTALL; fi

# copy the app to the container
ONBUILD COPY . $APP_SOURCE_DIR

# install all dependencies, build app, clean up
ONBUILD RUN cd $APP_SOURCE_DIR && \
            $BUILD_SCRIPTS_DIR/install-deps.sh && \
            $BUILD_SCRIPTS_DIR/install-node.sh && \
            $BUILD_SCRIPTS_DIR/install-phantom.sh && \
            $BUILD_SCRIPTS_DIR/install-mongo.sh && \
            $BUILD_SCRIPTS_DIR/install-meteor.sh && \
            $BUILD_SCRIPTS_DIR/build-meteor.sh && \
            $BUILD_SCRIPTS_DIR/post-build-cleanup.sh

# Default values for Meteor environment variables
ENV ROOT_URL http://localhost
ENV PORT 3000

EXPOSE 3000

WORKDIR $APP_BUNDLE_DIR/bundle

# start the app
ENTRYPOINT ["./entrypoint.sh"]
CMD ["node", "main.js"]
