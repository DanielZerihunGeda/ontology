#!/usr/bin/env bash
# Runs the official Neo4j MCP server in HTTP mode, for remote clients such as a
# a remote MCP client.
#
# In HTTP mode the server holds NO credentials. Every request must carry:
#   Authorization: Basic <aura user:password>       (else 401)
#   X-Neo4j-MCP-URI: neo4j+s://graph.example.org   (else 400; must be on the allow-list)
# and go to   POST /db/<database>/mcp            (plain /mcp is 404)
#
# Usage: bash integrations/neo4j/mcp-neo4j-http.sh [port] [extra flags, e.g. --read-only true]
# Expose it over HTTPS (TLS flags, a reverse proxy, or a tunnel) before connector platform can reach it.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${1:-8765}"; shift || true
set -a
# shellcheck source=/dev/null
. "$HERE/.env"
set +a
ALLOWED_URI_HOST="${NEO4J_MCP_URI#*://}"
# HTTP mode refuses to start if these are preset: they come per request instead.
unset NEO4J_MCP_URI NEO4J_MCP_USERNAME NEO4J_MCP_PASSWORD NEO4J_MCP_DATABASE

exec uvx neo4j-mcp-server@2.1.1 \
  --transport-mode http \
  --http-host "${MCP_HTTP_HOST:-127.0.0.1}" \
  --http-port "$PORT" \
  --http-allowed-uris "$ALLOWED_URI_HOST" \
  "$@"
