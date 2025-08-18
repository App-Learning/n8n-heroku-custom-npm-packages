#!/bin/sh
set -e

# ---------- PORT handling ----------
if [ -n "${PORT+x}" ] && [ -n "$PORT" ]; then
  export N8N_PORT="$PORT"
  echo "N8N will start on '$PORT'"
else
  echo "PORT variable not defined, leaving N8N to default port."
fi

# ---------- DB parsing from DATABASE_URL ----------
parse_url() {
  eval $(echo "$1" | sed -e "s#^\(\(.*\)://\)\?\(\([^:@]*\)\(:\(.*\)\)\?@\)\?\([^/?]*\)\(/\(.*\)\)\?#${PREFIX:-URL_}SCHEME='\2' ${PREFIX:-URL_}USER='\4' ${PREFIX:-URL_}PASSWORD='\6' ${PREFIX:-URL_}HOSTPORT='\7' ${PREFIX:-URL_}DATABASE='\9'#")
}

if [ -n "$DATABASE_URL" ]; then
  PREFIX="N8N_DB_" parse_url "$DATABASE_URL"

  # Masked echo (avoid dumping credentials in logs)
  echo "DB: ${N8N_DB_SCHEME}://${N8N_DB_USER}:********@${N8N_DB_HOSTPORT}/${N8N_DB_DATABASE}"

  # Separate host and port
  N8N_DB_HOST="$(echo "$N8N_DB_HOSTPORT" | sed -e 's,:.*,,g')"
  N8N_DB_PORT="$(echo "$N8N_DB_HOSTPORT" | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"

  export DB_TYPE="postgresdb"
  export DB_POSTGRESDB_HOST="$N8N_DB_HOST"
  export DB_POSTGRESDB_PORT="$N8N_DB_PORT"
  export DB_POSTGRESDB_DATABASE="$N8N_DB_DATABASE"
  export DB_POSTGRESDB_USER="$N8N_DB_USER"
  export DB_POSTGRESDB_PASSWORD="$N8N_DB_PASSWORD"
fi

# ---------- Puppeteer defaults (if not set via Dockerfile/env) ----------
: "${PUPPETEER_SKIP_CHROMIUM_DOWNLOAD:=true}"
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD
: "${PUPPETEER_EXECUTABLE_PATH:=/usr/bin/chromium-browser}"
export PUPPETEER_EXECUTABLE_PATH

# ---------- Register custom nodes path ----------
if [ -n "$N8N_CUSTOM_EXTENSIONS" ]; then
  export N8N_CUSTOM_EXTENSIONS="/opt/n8n-custom-nodes:${N8N_CUSTOM_EXTENSIONS}"
else
  export N8N_CUSTOM_EXTENSIONS="/opt/n8n-custom-nodes"
fi

# ---------- Diagnostics banner ----------
print_banner() {
  echo "----------------------------------------"
  echo "n8n Puppeteer Node - Environment Details"
  echo "----------------------------------------"
  command -v node >/dev/null 2>&1 && echo "Node.js version: $(node -v)" || echo "Node.js not found"
  command -v n8n  >/dev/null 2>&1 && echo "n8n version: $(n8n --version)" || echo "n8n not found"

  CHROME_VERSION=$("$PUPPETEER_EXECUTABLE_PATH" --version 2>/dev/null || echo "Chromium not found")
  echo "Chromium version: $CHROME_VERSION"

  PUPPETEER_PATH="/opt/n8n-custom-nodes/node_modules/n8n-nodes-puppeteer"
  if [ -f "$PUPPETEER_PATH/package.json" ]; then
    PUPPETEER_VERSION=$(node -p "require('$PUPPETEER_PATH/package.json').version")
    echo "n8n-nodes-puppeteer version: $PUPPETEER_VERSION"
    CORE_PUPPETEER_VERSION=$(cd "$PUPPETEER_PATH" && node -e "try { const v = require('puppeteer/package.json').version; console.log(v); } catch(e) { console.log('not found'); }")
    echo "Puppeteer core version: $CORE_PUPPETEER_VERSION"
  else
    echo "n8n-nodes-puppeteer: not installed"
  fi

  echo "Puppeteer executable path: $PUPPETEER_EXECUTABLE_PATH"
  echo "Custom nodes path: $N8N_CUSTOM_EXTENSIONS"
  echo "----------------------------------------"
}

print_banner

# ---------- Start n8n ----------
# Use exec so n8n receives signals directly (graceful shutdown)
exec n8n "$@"
