FROM n8nio/n8n:latest

USER root

# Install Chrome dependencies and Chrome for Puppeteer
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    freetype-dev \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    udev \
    ttf-liberation \
    font-noto-emoji

RUN npm install -g pnpm

# Tell Puppeteer to use installed Chrome instead of downloading it
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

WORKDIR /home/node/packages/cli

# Install custom npm packages
RUN pnpm install jsdom
RUN pnpm install node-fetch
# Install @notionhq/notion-mcp-server globally
RUN npx -y @notionhq/notion-mcp-server

# Install n8n-nodes-puppeteer in a permanent location
RUN mkdir -p /opt/n8n-custom-nodes && \
    cd /opt/n8n-custom-nodes && \
    npm install n8n-nodes-puppeteer && \
    chown -R node:node /opt/n8n-custom-nodes

# Custom entrypoint script
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh && \
    chown node:node /entrypoint.sh

USER node

ENTRYPOINT ["/entrypoint.sh"]
