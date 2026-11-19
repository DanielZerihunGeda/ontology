# Schema connector template

A schema-only connector with a parameterless `GET /get-schema` action.

| File | Purpose |
|---|---|
| [apiDefinition.swagger.yaml](apiDefinition.swagger.yaml) | Connector action and response definitions. |
| [Script.cs](Script.cs) | Converts the action to a graph query request and projects the schema response. |

The script uses a fixed read-only schema query and a sample size of 1000. The endpoint contains an example hostname and database identifier; credentials are supplied through the connection.

A successful response contains a `schema` array of `{key, value}` entries. An empty graph returns an empty array. Query or malformed-response failures return an error response. Sampling describes stored data and can omit rarely occurring properties.
