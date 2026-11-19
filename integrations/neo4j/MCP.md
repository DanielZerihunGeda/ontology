# MCP connection reference

The optional launchers use `neo4j-mcp-server@2.1.1` to expose graph operations through MCP.

| Operation | Purpose |
|---|---|
| `get-schema` | Read sampled labels, properties and relationship metadata. |
| `read-cypher` | Execute read-only graph queries. |
| `write-cypher` | Execute mutations when write access is enabled. |

## Local configuration

The launchers read an ignored `.env` beside them. A generic configuration has these variable names:

```dotenv
NEO4J_MCP_URI=neo4j+s://graph.example.org
NEO4J_MCP_USERNAME=example-user
NEO4J_MCP_PASSWORD=<local-password>
NEO4J_MCP_DATABASE=example-db
NEO4J_MCP_TELEMETRY=false
NEO4J_MCP_SCHEMA_SAMPLE_SIZE=1000
NEO4J_MCP_LOG_LEVEL=info
```

The example host and database are placeholders. Connection values belong in local configuration.

The root [.mcp.example.json](../../.mcp.example.json) illustrates a stdio client registration. Its relative launcher path assumes the client starts from the repository root. The HTTP launcher derives its allowed host from local configuration and receives credentials with each request.

## Reference files

- [Stdio launcher](mcp-neo4j.sh)
- [HTTP launcher](mcp-neo4j-http.sh)
- [Read-only diagnostic](mcp-smoke-test.sh)
- [MCP connector template](connectors/mcp/README.md)
- [Schema connector template](connectors/get-schema/README.md)
