#!/usr/bin/env bash
# Smoke test for the Neo4j MCP server: handshake, list tools, call get-schema and read-cypher.
# Read-only: it never calls write-cypher.
# Usage: bash integrations/neo4j/mcp-smoke-test.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$(mktemp)"

{
  printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"smoke-test","version":"1"}}}'
  sleep 6   # first run downloads the package; raise this if the test prints nothing
  printf '%s\n' \
    '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
    '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
    '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get-schema","arguments":{}}}' \
    '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"read-cypher","arguments":{"query":"MATCH (n) RETURN count(n) AS nodes"}}}'
  sleep 20
} | timeout 90 bash "$HERE/mcp-neo4j.sh" 2>"$LOG" | python3 -I -c '
import json, sys
seen = set()
for line in sys.stdin:
    try:
        m = json.loads(line)
    except ValueError:
        continue
    i = m.get("id"); seen.add(i)
    if i == 1:
        print("connected   :", m["result"]["serverInfo"]["name"])
    elif i == 2:
        print("tools       :", ", ".join(t["name"] for t in m["result"]["tools"]))
    elif i in (3, 4):
        r = m.get("result", {})
        name = "schema      :" if i == 3 else "node count  :"
        status = "ERROR" if r.get("isError") or "error" in m else "ok"
        print(name, status, r.get("content", [{}])[0].get("text", m.get("error"))[:300])
missing = {1, 2, 3, 4} - seen
sys.exit(f"no response for request ids {sorted(missing)} (see log)" if missing else 0)
' || { echo "--- server log: $LOG"; grep -iv password "$LOG" | tail -20; exit 1; }
rm -f "$LOG"
