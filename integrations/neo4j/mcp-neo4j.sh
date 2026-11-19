#!/usr/bin/env bash
# Starts the official Neo4j MCP server (github.com/neo4j/mcp, PyPI: neo4j-mcp-server)
# against the Neo4j instance in .env. Credentials stay in .env; .mcp.json only points here.
# .env uses the server's own NEO4J_MCP_* names, so it is loaded as-is.
# Tools exposed: get-schema, read-cypher, write-cypher.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -a
# shellcheck source=/dev/null
. "$HERE/.env"
set +a

# Pinned version. Extra flags are passed through, e.g. --read-only true.
exec uvx neo4j-mcp-server@2.1.1 "$@"
