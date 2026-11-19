# Historical material

The current schema is represented under [model/](../model/). This directory preserves earlier schema representations and reference material using generic names and example namespaces.

| Path | Historical role |
|---|---|
| [instructions/instruction-v1.md](instructions/instruction-v1.md) | Earlier agent instruction snapshot with separate Payment and ProgressReport labels. |
| [ontologies/ontology_consolidated.md](ontologies/ontology_consolidated.md) | Comparison of the four earlier Turtle variants kept beside it. |
| [model/pre-instruction-v2/model.tsv](model/pre-instruction-v2/model.tsv) | Structured local model before alignment with the updated V2 instruction. |
| [model/pre-instruction-v2/templates/](model/pre-instruction-v2/templates/) | Superseded Payment/ProgressReport node and project-relationship headers. |
| [model/pre-instruction-v2/import_csv/](model/pre-instruction-v2/import_csv/) | Corresponding earlier flat import headers. |
| [local-setup/custom_mcp.sh](local-setup/custom_mcp.sh) | Earlier environment-variable mapping snippet; its paths reflect the previous layout. |
| [scaffold/main.py](scaffold/main.py) | Original Python starter, unrelated to the reference workflow. |

The preserved CSVs contain headers only. Their retirement records the model change; it does not migrate existing graph data. Legacy reconciliation and preservation rules are documented in the [current workflow](../docs/workflow.md#earlier-schema-representations).
