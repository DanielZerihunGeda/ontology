# Graph connection references

Optional connection helpers and connector templates for a Neo4j-compatible knowledge graph.

| Path | Purpose |
|---|---|
| [MCP.md](MCP.md) | General local MCP connection reference. |
| [mcp-neo4j.sh](mcp-neo4j.sh) | Local stdio launcher. |
| [mcp-neo4j-http.sh](mcp-neo4j-http.sh) | HTTP launcher with credentials supplied per request. |
| [mcp-smoke-test.sh](mcp-smoke-test.sh) | Read-only connection diagnostic. |
| [connectors/mcp/](connectors/mcp/) | MCP connector definition and policy template. |
| [connectors/get-schema/](connectors/get-schema/) | Schema connector definition and request/response adaptation. |
| [connectors/query/](connectors/query/) | Direct graph query connector template. |
| [../../.mcp.example.json](../../.mcp.example.json) | Portable example of local client configuration. |

Addresses and database identifiers in published templates are placeholders. Local credentials and client settings are ignored by Git.
