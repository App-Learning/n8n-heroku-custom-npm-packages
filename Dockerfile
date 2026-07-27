ARG N8N_VERSION=latest

# The n8n runtime image intentionally contains no package-manager toolchain.
# Install custom JavaScript dependencies in a separate build stage instead.
FROM node:24-alpine3.23 AS custom-dependencies
WORKDIR /opt/custom-node-modules
RUN npm install --omit=dev --no-package-lock jsdom node-fetch

FROM n8nio/n8n:${N8N_VERSION}

# n8n's modern Alpine image removes apk-tools; copy minimal apk bits from Alpine.
COPY --from=alpine:3.23 /sbin/apk /sbin/apk
COPY --from=alpine:3.23 /usr/lib/libapk.so* /usr/lib/

USER root

RUN apk add --no-cache graphicsmagick

# Make the custom packages available to n8n and permit them in Code nodes.
COPY --from=custom-dependencies /opt/custom-node-modules/node_modules /opt/custom-node-modules/node_modules
ENV NODE_PATH=/opt/custom-node-modules/node_modules
ENV NODE_FUNCTION_ALLOW_EXTERNAL=jsdom,node-fetch

WORKDIR /home/node

# --- Copy your entrypoint ---
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh && \
    chown node:node /entrypoint.sh

USER node

ENTRYPOINT []
CMD ["/entrypoint.sh"]
