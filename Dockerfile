ARG N8N_VERSION=latest
FROM n8nio/n8n:${N8N_VERSION}

# n8n's modern Alpine image removes apk-tools; copy minimal apk bits from Alpine.
COPY --from=alpine:3.23 /sbin/apk /sbin/apk
COPY --from=alpine:3.23 /usr/lib/libapk.so* /usr/lib/

USER root

WORKDIR /home/node/packages/cli

# --- Install custom npm packages ---
RUN pnpm install jsdom \
    && pnpm install node-fetch

# --- Copy your entrypoint ---
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh && \
    chown node:node /entrypoint.sh

USER node

ENTRYPOINT []
CMD ["/entrypoint.sh"]
