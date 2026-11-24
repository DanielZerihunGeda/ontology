"""Generate Neo4j import artefacts and a Fabric ontology from model.tsv.

model.tsv is the master. Edit it, then run:

    python3 generate.py

Outputs (overwritten every run):
    templates/nodes/<Label>.csv           empty CSV with the columns to fill
    templates/relationships/<TYPE>.csv    empty CSV with the columns to fill
    import.cypher                         indexes + LOAD CSV script (Neo4j)
    model.json                            Data Importer (Data Importer) model, format 3.0.0
    post_import.cypher                    run after a graph Import load: indexes + *Norm copies
    ontology.ttl                          OWL/Turtle for Microsoft Fabric
    ../diagram/*.mmd                     Mermaid schema and relationship overview
"""
import csv
import re
from collections import OrderedDict
from pathlib import Path

HERE = Path(__file__).resolve().parent
NS = "https://example.org/ontology#"


# --------------------------------------------------------------------------- model
def load_model(path):
    settings, nodes, rels = {}, OrderedDict(), OrderedDict()
    with open(path, newline="") as f:
        for r in csv.DictReader(f, delimiter="\t"):
            kind = r["kind"]
            if kind == "setting":
                settings[r["name"]] = r["value"]
            elif kind == "node":
                nodes[r["owner"]] = {**r, "props": []}
            elif kind == "relationship":
                rels[r["owner"]] = {**r, "props": [], "fromList": r["from"].split("|")}
            elif kind == "property":
                owner = nodes.get(r["owner"]) or rels.get(r["owner"])
                if owner is None:
                    raise SystemExit(f"property {r['owner']}.{r['name']}: owner must be declared before its properties")
                owner["props"].append(r)
            else:
                raise SystemExit(f"unknown kind: {kind}")
    return settings, nodes, rels


def snake(label):
    return re.sub(r"(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])", "_", label).lower()


def csv_columns(p):
    """Properties the user fills in. Derived *Norm fields are computed on import;
    embeddings may be supplied pre-computed, so they stay in the template."""
    return not p["derivedFrom"] or p["search"] == "embedding"


# --------------------------------------------------------------------------- templates
def write_templates(nodes, rels):
    nd, rd = HERE / "templates" / "nodes", HERE / "templates" / "relationships"
    nd.mkdir(parents=True, exist_ok=True)
    rd.mkdir(parents=True, exist_ok=True)
    for label, n in nodes.items():
        cols = [p["name"] for p in n["props"] if csv_columns(p)]
        (nd / f"{label}.csv").write_text(",".join(cols) + "\n")
    for old in rd.glob("*.csv"):
        old.unlink()
    for rtype, r in rels.items():
        cols = ["startId", "endId"] + [p["name"] for p in r["props"]]
        for frm in r["fromList"]:
            (rd / rel_file(rtype, r, frm)).write_text(",".join(cols) + "\n")


def rel_file(rtype, r, frm):
    """One file per (type, source label): Data Importer maps a file to exactly one
    pair of labels and cannot filter rows, so multi-source types are split."""
    return f"{rtype}__{frm}.csv" if len(r["fromList"]) > 1 else f"{rtype}.csv"


# --------------------------------------------------------------------------- cypher
def blank(x):
    return f"(row.{x} IS NULL OR trim(row.{x}) = '')"


def convert(p, sep):
    n, t = p["name"], p["type"]
    v = f"trim(row.{n})"
    expr = {
        "STRING": v,
        "INTEGER": f"toInteger({v})",
        "FLOAT": f"toFloat({v})",
        "BOOLEAN": f"toBoolean({v})",
        "DATETIME": f"datetime({v})",
        "LIST<STRING>": f"[x IN split({v}, '{sep}') WHERE trim(x) <> '' | trim(x)]",
        "LIST<FLOAT>": f"[x IN split({v}, '{sep}') | toFloat(x)]",
    }[t]
    return f"CASE WHEN {blank(n)} THEN null ELSE {expr} END"


def normalise(src, var="row"):
    # Upper-case, keep only A-Z and 0-9. Pure Cypher, no plugin needed.
    empty = blank(src) if var == "row" else f"({var}.{src} IS NULL OR trim({var}.{src}) = '')"
    return (f"CASE WHEN {empty} THEN null ELSE "
            f"reduce(s = '', c IN split(toUpper({var}.{src}), '') | "
            f"s + CASE WHEN c =~ '[A-Z0-9]' THEN c ELSE '' END) END")


def prop_map(props, sep, indent):
    lines = []
    for p in props:
        if p["name"] == "id":
            continue
        if p["derivedFrom"] and p["search"] != "embedding":
            lines.append(f"{p['name']}: {normalise(p['derivedFrom'])}")
        else:
            lines.append(f"{p['name']}: {convert(p, sep)}")
    pad = " " * indent
    return "{\n" + ",\n".join(pad + "  " + l for l in lines) + "\n" + pad + "}"


def index_lines(settings, nodes):
    """Search indexes (everything except the id constraints)."""
    dims = settings["embeddingDimensions"]
    sim = settings["similarityFunction"]
    out = []
    w = out.append
    w("// ---------------------------------------------------------------- exact-match lookups")
    for label, n in nodes.items():
        for p in n["props"]:
            if p["search"] == "exact":
                w(f"CREATE INDEX {snake(label)}_{snake(p['name'])} IF NOT EXISTS FOR (n:{label}) ON (n.{p['name']});")
    w("")

    w("// ---------------------------------------------------------------- controlled-value filters")
    w("// Dates/amounts are left unindexed: queries usually start from a Project and walk FOR_PROJECT.")
    for label, n in nodes.items():
        for p in n["props"]:
            if p["search"] == "filter" and p["allowedValues"]:
                w(f"CREATE INDEX {snake(label)}_{snake(p['name'])} IF NOT EXISTS FOR (n:{label}) ON (n.{p['name']});")
    w("")

    w("// ---------------------------------------------------------------- full-text (Lucene)")
    w("// Query: CALL db.index.fulltext.queryNodes('<index>', $text) YIELD node, score")
    for label, n in nodes.items():
        fields = [p["name"] for p in n["props"] if "lucene" in p["search"].split("|")]
        if fields:
            on = ", ".join(f"n.{f}" for f in fields)
            w(f"CREATE FULLTEXT INDEX {snake(label)}_text IF NOT EXISTS FOR (n:{label}) ON EACH [{on}];")
    w("")

    w(f"// ---------------------------------------------------------------- vector ({settings['embeddingModel']}, {dims} dims, {sim})")
    w("// Query: CALL db.index.vector.queryNodes('<index>', $k, $embedding) YIELD node, score")
    for label, n in nodes.items():
        for p in n["props"]:
            if p["search"] == "embedding":
                w(f"CREATE VECTOR INDEX {snake(label)}_{snake(p['name'])} IF NOT EXISTS FOR (n:{label}) ON (n.{p['name']})\n"
                  f"  OPTIONS {{ indexConfig: {{ `vector.dimensions`: {dims}, `vector.similarity_function`: '{sim}' }} }};")
    w("")

    return out


def embed_lines(settings, nodes):
    dims = settings["embeddingDimensions"]
    out = []
    w = out.append
    w(f"""// ---------------------------------------------------------------- optional: embed in the database
// Use this instead of pre-computed summaryEmbedding values. Needs the GenAI plugin
// (database plugin configuration: NEO4J_PLUGINS='["genai"]') and an OpenAI key:
//   :param openaiKey => 'sk-...'
// Newer plugin versions also offer ai.text.embed(); genai.vector.encode still works.""")
    for label, n in nodes.items():
        for p in n["props"]:
            if p["search"] == "embedding":
                src = p["derivedFrom"]
                w(f"// MATCH (n:{label}) WHERE n.{src} IS NOT NULL AND n.{p['name']} IS NULL\n"
                  f"// CALL (n) {{ SET n.{p['name']} = genai.vector.encode(n.{src}, 'OpenAI', "
                  f"{{token: $openaiKey, model: '{settings['embeddingModel']}', dimensions: {dims}}}) }} IN TRANSACTIONS OF 100 ROWS;")
    return out


def write_cypher(settings, nodes, rels):
    sep = settings.get("listSeparator", "|")
    out = []
    w = out.append

    w(f"""// =====================================================================
// Knowledge graph: schema + CSV import
// Generated from model.tsv by generate.py. Do not edit by hand.
// Runs unchanged on Neo4j Neo4j Neo4j (5.23+ / 2025.x+).
//
// 1. Set where the CSV files are (the folder that contains nodes/ and relationships/):
//      Neo4j:         :param baseUrl => 'https://<your-host>/graph-data/'
//      Self-hosted:  :param baseUrl => 'file:///'   (files inside Neo4j's import folder)
// 2. Run this whole file (Neo4j Browser / Query, or cypher-shell -f import.cypher).
//
// CSV conventions: header row as in templates/, comma-separated, UTF-8.
// Lists (aliases, names, embeddings) go in one cell separated by '{sep}'.
// Dates are ISO yyyy-mm-dd (stored as DATETIME at 00:00 UTC) or full ISO datetimes. Empty cells are stored as missing properties.
// Re-running is safe: nodes and relationships are MERGEd on id.
// =====================================================================
""")

    w("// ---------------------------------------------------------------- uniqueness")
    for label in nodes:
        w(f"CREATE CONSTRAINT {snake(label)}_id IF NOT EXISTS FOR (n:{label}) REQUIRE n.id IS UNIQUE;")
    w("")

    out += index_lines(settings, nodes)

    w("// ---------------------------------------------------------------- nodes")
    for label, n in nodes.items():
        w(f"LOAD CSV WITH HEADERS FROM $baseUrl + 'nodes/{label}.csv' AS row\n"
          f"WITH row WHERE NOT {blank('id')}\n"
          f"CALL (row) {{\n"
          f"  MERGE (n:{label} {{id: trim(row.id)}})\n"
          f"  SET n += {prop_map(n['props'], sep, 2)}\n"
          f"}} IN TRANSACTIONS OF 1000 ROWS;\n")

    w("// ---------------------------------------------------------------- relationships")
    for rtype, r in rels.items():
        for frm in r["fromList"]:
            body = f"  MERGE (s)-[r:{rtype}]->(e)\n"
            if r["props"]:
                body += f"  SET r += {prop_map(r['props'], sep, 2)}\n"
            w(f"LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/{rel_file(rtype, r, frm)}' AS row\n"
              f"WITH row WHERE NOT {blank('startId')} AND NOT {blank('endId')}\n"
              f"CALL (row) {{\n"
              f"  MATCH (s:{frm} {{id: trim(row.startId)}})\n"
              f"  MATCH (e:{r['to']} {{id: trim(row.endId)}})\n"
              f"{body}"
              f"}} IN TRANSACTIONS OF 1000 ROWS;\n")

    out += embed_lines(settings, nodes)
    (HERE / "import.cypher").write_text("\n".join(out) + "\n")


# --------------------------------------------------------------------------- fabric ttl
XSD = {"STRING": "xsd:string", "INTEGER": "xsd:integer", "FLOAT": "xsd:decimal",
       "BOOLEAN": "xsd:boolean", "DATETIME": "xsd:dateTime", "LIST<STRING>": "xsd:string", "LIST<FLOAT>": "xsd:string"}


def lit(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def write_ttl(settings, nodes, rels):
    """Mirrors the structure Fabric itself exports: one owl:DatatypeProperty per
    (class, property), named Class__prop when the name is shared by several
    classes; one owl:ObjectProperty per (type, source class), since Fabric
    gives each relationship a single domain. rdfs:label always carries the
    clean Neo4j name."""
    owners = {}
    for label, n in nodes.items():
        for p in n["props"]:
            owners.setdefault(p["name"], []).append(label)

    o = [
        "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>.",
        "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>.",
        "@prefix xsd: <http://www.w3.org/2001/XMLSchema#>.",
        "@prefix owl: <http://www.w3.org/2002/07/owl#>.",
        f"@prefix kg: <{NS}>.",
        "",
        f"<{NS[:-1]}> a owl:Ontology;",
        '    rdfs:label "Knowledge Graph";',
        "    rdfs:comment " + lit("Construction contract administration. Generated from model/model.tsv; "
                                  "the Neo4j model is the master. Lists are stored as text here; "
                                  "relationship properties are listed in the relationship comment.") + ";",
        '    owl:versionInfo "1.0".',
        "",
    ]
    for label, n in nodes.items():
        o += [f"kg:{label} a owl:Class;", f"    rdfs:label {lit(label)};",
              f"    rdfs:comment {lit(n['description'])}.", ""]
        for p in n["props"]:
            if p["search"] == "embedding":
                continue  # vectors are a Neo4j storage detail, not part of the visual model
            shared = len(owners[p["name"]]) > 1
            iri = f"kg:{label}__{p['name']}" if shared else f"kg:{p['name']}"
            comment = p["description"]
            if p["allowedValues"]:
                comment += " Allowed values: " + ", ".join(p["allowedValues"].split("|")) + "."
            if p["type"].startswith("LIST"):
                comment += " Multi-valued."
            o += [f"{iri} a owl:DatatypeProperty;",
                  f"    rdfs:domain kg:{label};",
                  f"    rdfs:label {lit(p['name'])};",
                  f"    rdfs:range {XSD[p['type']]};",
                  f"    rdfs:comment {lit(comment)}"
                  + (";\n    <urn:fabric-internal:qualifiedPropertyName> \"true\"." if shared else "."), ""]
    for rtype, r in rels.items():
        comment = r["description"]
        if r["props"]:
            comment += " Properties: " + "; ".join(
                f"{p['name']} ({', '.join(p['allowedValues'].split('|')) if p['allowedValues'] else p['type']})"
                for p in r["props"]) + "."
        for frm in r["fromList"]:
            iri = f"kg:{rtype}__{frm}" if len(r["fromList"]) > 1 else f"kg:{rtype}"
            o += [f"{iri} a owl:ObjectProperty;",
                  f"    rdfs:domain kg:{frm};",
                  f"    rdfs:label {lit(rtype)};",
                  f"    rdfs:range kg:{r['to']};",
                  f"    rdfs:comment {lit(comment)}.", ""]
    (HERE / "ontology.ttl").write_text("\n".join(o))


# --------------------------------------------------------------------------- data importer
# Format 3.0.0, as exported by Data Importer (console.neo4j.io -> Import -> ... -> Open model).
# Mirrors real 2026 exports: key constraint per node, one table per CSV template,
# fromMappings/toMappings keyed by the endpoint's key-property ref.
IMPORTER_TYPE = {"STRING": {"type": "string"}, "INTEGER": {"type": "integer"}, "FLOAT": {"type": "float"},
                 "BOOLEAN": {"type": "boolean"}, "DATETIME": {"type": "datetime"},
                 "LIST<STRING>": {"type": "array", "items": {"type": "string"}}}


def importer_type(p, settings):
    if p["type"] == "LIST<FLOAT>":
        return {"type": "vector", "items": {"type": "float"}, "dimension": int(settings["embeddingDimensions"])}
    return IMPORTER_TYPE[p["type"]]


def write_model_json(settings, nodes, rels):
    import json
    import math

    ref = lambda i: {"$ref": "#" + i}
    pid = lambda owner, name: f"p:{owner}:{name}"
    node_labels, node_types, constraints, keys, tables, node_maps, vis = [], [], [], [], [], [], []

    # layout: Project in the middle, Organization to the right, records on a ring
    others = [l for l in nodes if l not in ("Project", "Organization")]
    pos = {"Project": (0, 0), "Organization": (420, 0)}
    for i, label in enumerate(others):
        a = math.pi / 2 + 2 * math.pi * i / len(others)
        pos[label] = (round(-60 + 330 * math.cos(a), 1), round(330 * math.sin(a), 1))

    for i, (label, n) in enumerate(nodes.items()):
        nl, nt = f"nl:{label}", f"n:{label}"
        mapped = [p for p in n["props"] if csv_columns(p)]
        node_labels.append({"$id": nl, "token": label, "properties": [
            {"$id": pid(label, p["name"]), "token": p["name"], "type": importer_type(p, settings),
             "nullable": p["required"] != "yes"} for p in mapped]})
        node_types.append({"$id": nt, "labels": [ref(nl)]})
        constraints.append({"$id": f"c:{label}", "name": f"{snake(label)}_id", "constraintType": "key",
                            "entityType": "node", "nodeLabel": ref(nl), "properties": [ref(pid(label, "id"))]})
        keys.append({"node": ref(nt), "keyProperties": [ref(pid(label, "id"))]})
        table = f"{label}.csv"
        tables.append({"name": table, "expanded": True, "fields": [
            {"name": p["name"], "sample": "", "recommendedType": importer_type(p, settings)} for p in mapped]})
        node_maps.append({"node": ref(nt), "tableName": table, "propertyMappings": [
            {"fieldName": p["name"], "property": ref(pid(label, p["name"]))} for p in mapped]})
        x, y = pos[label]
        vis.append({"id": nt, "position": {"x": x, "y": y}})

    rel_types, rel_obj_types, rel_maps = [], [], []
    for rtype, r in rels.items():
        rt = f"rt:{rtype}"
        rel_types.append({"$id": rt, "token": rtype, "properties": [
            {"$id": pid(rtype, p["name"]), "token": p["name"], "type": importer_type(p, settings),
             "nullable": p["required"] != "yes"} for p in r["props"]]})
        for frm in r["fromList"]:
            ro = f"r:{rtype}:{frm}"
            rel_obj_types.append({"$id": ro, "type": ref(rt), "from": ref(f"n:{frm}"), "to": ref(f"n:{r['to']}")})
            table = rel_file(rtype, r, frm)
            tables.append({"name": table, "expanded": True, "fields":
                           [{"name": "startId", "sample": "", "recommendedType": {"type": "string"}},
                            {"name": "endId", "sample": "", "recommendedType": {"type": "string"}}] +
                           [{"name": p["name"], "sample": "", "recommendedType": importer_type(p, settings)} for p in r["props"]]})
            rel_maps.append({"relationship": ref(ro), "tableName": table,
                             "fromMappings": {"#" + pid(frm, "id"): "startId"},
                             "toMappings": {"#" + pid(r["to"], "id"): "endId"},
                             "propertyMappings": [{"fieldName": p["name"], "property": ref(pid(rtype, p["name"]))}
                                                  for p in r["props"]]})

    sep = settings.get("listSeparator", "|")
    model = {
        "version": "3.0.0",
        "visualisation": {"nodes": vis},
        "dataModel": {
            "version": "3.0.0",
            "graphSchemaRepresentation": {"version": "1.0.0", "graphSchema": {
                "nodeLabels": node_labels, "relationshipTypes": rel_types,
                "nodeObjectTypes": node_types, "relationshipObjectTypes": rel_obj_types,
                "constraints": constraints, "indexes": []}},
            "graphSchemaExtensionsRepresentation": {"nodeKeyProperties": keys},
            "graphMappingRepresentation": {
                "dataSourceSchema": {"type": "local", "tableSchemas": tables},
                "nodeMappings": node_maps, "relationshipMappings": rel_maps},
            "configurations": {"idsToIgnore": [], "arrayDelimiter": sep, "vectorDelimiter": sep},
        },
    }
    (HERE / "model.json").write_text(json.dumps(model, indent=2) + "\n")


def write_post_import(settings, nodes):
    """Run once after a graph Import (Data Importer) load: it cannot compute the
    *Norm copies or create full-text / vector / lookup indexes."""
    out = ["""// =====================================================================
// Knowledge graph: run AFTER loading data with Data Importer (model.json)
// Generated from model.tsv by generate.py. Do not edit by hand.
// Adds what Data Importer cannot: search indexes and normalised reference copies.
// Safe to re-run. Not needed after import.cypher, which already does both.
// =====================================================================
"""]
    out += index_lines(settings, nodes)
    out.append("// ---------------------------------------------------------------- normalised reference copies")
    for label, n in nodes.items():
        for p in n["props"]:
            if p["derivedFrom"] and p["search"] != "embedding":
                out.append(f"MATCH (n:{label}) WHERE n.{p['derivedFrom']} IS NOT NULL\n"
                           f"SET n.{p['name']} = {normalise(p['derivedFrom'], 'n')};")
    out.append("")
    out += embed_lines(settings, nodes)
    (HERE / "post_import.cypher").write_text("\n".join(out) + "\n")


# --------------------------------------------------------------------------- diagrams
def write_diagrams(nodes, rels):
    """Keep both Mermaid views aligned with the structured schema."""
    from html import escape

    directory = HERE.parent / "diagram"
    directory.mkdir(parents=True, exist_ok=True)
    header = ["%% Generated from model/model.tsv by model/generate.py. Do not edit by hand.",
              "%% Schema reference: instructions/instruction-v2.md, Model section."]
    overview = [*header, "flowchart LR",
                "    %% ! marks required properties; all other properties are optional.",
                "    %% Arrows show permitted source-to-target patterns, without cardinality rules."]
    schema = [*header, "classDiagram", "    direction LR",
              "    %% Arrows show permitted source-to-target patterns, without cardinality rules.",
              "    %% Required properties and closed enums are listed in class notes."]

    for label, node in nodes.items():
        fields = [f"<b>{label}</b>"]
        for prop in node["props"]:
            required_mark = "!" if prop["required"] == "yes" else ""
            fields.append(f"{prop['name']}: {escape(prop['type'])}{required_mark}")
        overview.append(f'    {label}["' + "<br/>".join(fields) + '"]')
        schema.append(f"    class {label} {{")
        for prop in node["props"]:
            # Mermaid uses tildes to express generic types such as LIST~FLOAT~.
            datatype = prop["type"].replace("<", "~").replace(">", "~")
            schema.append(f"        {datatype} {prop['name']}")
        schema.append("    }")
        required = ", ".join(p["name"] for p in node["props"] if p["required"] == "yes")
        notes = [f"Required: {required}. Other properties are optional."]
        for prop in node["props"]:
            if prop["allowedValues"]:
                notes.append(f"{prop['name']}: {prop['allowedValues'].replace('|', ', ')}")
        if label == "Report":
            notes.append("reportType is an open string classification.")
        # Relationship properties belong to edges; describe them without inventing classes.
        for rtype, rel in rels.items():
            if rel["to"] == label:
                for prop in rel["props"]:
                    required_text = "required" if prop["required"] == "yes" else "optional"
                    notes.append(f"{rtype}.{prop['name']} ({required_text} {prop['type']}): "
                                 f"{prop['allowedValues'].replace('|', ', ')}")
        schema.append(f'    note for {label} "' + "<br/>".join(notes) + '"')

    overview.append("")
    schema.append("")
    for rtype, rel in rels.items():
        edge_label = rtype
        if rel["props"]:
            properties = ", ".join(
                f"{p['name']} {p['type']}"
                + (" required" if p["required"] == "yes" else " optional")
                for p in rel["props"]
            )
            edge_label += f" ({properties})"
        for source in rel["fromList"]:
            overview.append(f'    {source} -->|"{edge_label}"| {rel["to"]}')
            schema.append(f"    {source} --> {rel['to']} : {edge_label}")

    (directory / "overview.mmd").write_text("\n".join(overview) + "\n")
    (directory / "graph-schema.mmd").write_text("\n".join(schema) + "\n")


if __name__ == "__main__":
    s, n, r = load_model(HERE / "model.tsv")
    write_templates(n, r)
    write_cypher(s, n, r)
    write_ttl(s, n, r)
    write_model_json(s, n, r)
    write_post_import(s, n)
    write_diagrams(n, r)
    print(f"{len(n)} node labels, {len(r)} relationship types -> templates/, import.cypher, "
          f"model.json, post_import.cypher, ontology.ttl, ../diagram/*.mmd")
