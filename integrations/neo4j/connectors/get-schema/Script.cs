using System;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

public class Script : ScriptBase
{
    public override async Task<HttpResponseMessage> ExecuteAsync()
    {
        if (this.Context.Request.Method != HttpMethod.Get)
        {
            var error = Error(HttpStatusCode.MethodNotAllowed, "Only GET is supported.");
            error.Content.Headers.Allow.Add("GET");
            return error;
        }

        // This is an example endpoint. Credentials are supplied through
        // the connector's authentication connection.
        this.Context.Request.RequestUri = new Uri(
            "https://graph.example.org/db/example-db/query/v2");
        this.Context.Request.Method = HttpMethod.Post;
        this.Context.Request.Headers.Accept.Clear();
        this.Context.Request.Headers.Accept.Add(
            new MediaTypeWithQualityHeaderValue("application/json"));
        this.Context.Request.Content = CreateJsonContent(new JObject
        {
            // Exact schema projection used by neo4j-mcp-server 2.1.1.
            ["statement"] = "CALL apoc.meta.schema({sample: $sampleSize}) YIELD value UNWIND keys(value) as key WITH key, value[key] as value RETURN key, value { .properties, .type, .relationships } as value",
            ["parameters"] = new JObject { ["sampleSize"] = 1000 },
            ["accessMode"] = "Read"
        }.ToString(Formatting.None));

        var response = await this.Context.SendAsync(
            this.Context.Request, this.CancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            return response;
        }

        // The Query API can report Cypher errors in a successful HTTP 202.
        try
        {
            var body = JObject.Parse(
                await response.Content.ReadAsStringAsync().ConfigureAwait(false));
            var errors = body["errors"] as JArray;
            if (errors != null && errors.Count > 0)
            {
                response.Dispose();
                return Error(HttpStatusCode.BadGateway, "Neo4j schema query failed.");
            }

            var data = body["data"] as JObject;
            var fields = data == null ? null : data["fields"] as JArray;
            var rows = data == null ? null : data["values"] as JArray;
            if (fields == null || fields.Count != 2 ||
                (string)fields[0] != "key" || (string)fields[1] != "value" || rows == null)
            {
                response.Dispose();
                return Error(HttpStatusCode.BadGateway, "Invalid Neo4j schema response.");
            }

            var schema = new JArray();
            foreach (var row in rows)
            {
                var values = row as JArray;
                if (values == null || values.Count != 2 ||
                    values[0].Type != JTokenType.String || !(values[1] is JObject))
                {
                    response.Dispose();
                    return Error(HttpStatusCode.BadGateway, "Invalid Neo4j schema row.");
                }
                schema.Add(new JObject { ["key"] = values[0], ["value"] = values[1] });
            }

            response.Dispose();
            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = CreateJsonContent(
                    new JObject { ["schema"] = schema }.ToString(Formatting.None))
            };
        }
        catch (JsonException)
        {
            response.Dispose();
            return Error(HttpStatusCode.BadGateway, "Invalid JSON from Neo4j.");
        }
    }

    private HttpResponseMessage Error(HttpStatusCode status, string message)
    {
        return new HttpResponseMessage(status)
        {
            Content = CreateJsonContent(
                new JObject { ["error"] = message }.ToString(Formatting.None))
        };
    }
}
