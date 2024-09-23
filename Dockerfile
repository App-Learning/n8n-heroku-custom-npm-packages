FROM n8nio/n8n:latest

USER root

WORKDIR /home/node/packages/cli

# Install custom npm packages
RUN pnpm install jsdom

ENTRYPOINT []

COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]