# MCP connector template

A reference connector for forwarding MCP requests to a graph server.

| File | Purpose |
|---|---|
| [apiDefinition.swagger.yaml](apiDefinition.swagger.yaml) | Connector definition with streamable HTTP metadata. |
| [apiProperties.json](apiProperties.json) | Connection fields and a graph-URI header policy. |
| [../../mcp-neo4j-http.sh](../../mcp-neo4j-http.sh) | Optional local HTTP launcher. |

The template uses example hostnames and `example-db` as a database placeholder. The request includes a graph URI header and connection-supplied authentication. The server exposes schema reads, graph reads and, when enabled, graph writes.

These files describe a reusable connection shape rather than an existing service configuration.
