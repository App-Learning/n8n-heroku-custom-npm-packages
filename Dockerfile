ARG N8N_VERSION=latest
FROM n8nio/n8n:${N8N_VERSION}

# n8n's modern Alpine image removes apk-tools; copy minimal apk bits from Alpine.
COPY --from=alpine:3.23 /sbin/apk /sbin/apk
COPY --from=alpine:3.23 /usr/lib/libapk.so* /usr/lib/

USER root

# Install Chromium and runtime deps for Puppeteer.
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    udev \
    ttf-liberation \
    font-noto-emoji

# Tell Puppeteer to use installed Chrome instead of downloading it
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

WORKDIR /home/node/packages/cli

# --- Install custom npm packages ---
RUN pnpm install jsdom \
    && pnpm install node-fetch

# --- Install n8n-nodes-puppeteer in permanent location ---
RUN mkdir -p /opt/n8n-custom-nodes && \
    cd /opt/n8n-custom-nodes && \
    pnpm add n8n-nodes-puppeteer && \
    chown -R node:node /opt/n8n-custom-nodes

# --- Copy your entrypoint ---
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh && \
    chown node:node /entrypoint.sh

USER node

ENTRYPOINT []
CMD ["/entrypoint.sh"]
