# Knowledge graph models

Ontology models and reference documentation for representing projects, organizations, documents, reports and financial records in a knowledge graph.

The model includes **11 node labels and 14 relationship types**, with typed properties, optional document provenance and semantic retrieval metadata.

## Contents

| Path | Description |
|---|---|
| [model/](model/) | Structured schema, OWL/Turtle representation, importer metadata and CSV templates. |
| [diagram/](diagram/) | Mermaid graph schema and relationship overview. |
| [docs/workflow.md](docs/workflow.md) | General document-to-graph workflow. |
| [integrations/neo4j/](integrations/neo4j/) | Optional connection helpers and connector templates. |
| [archive/](archive/) | Earlier schema variants and reference material. |

## Model overview

The model covers `Project`, `Organization`, `Letter`, `EOTClaim`, `Agreement`, `Proposal`, `Drawing`, `BOQ`, `Schedule`, `Report` and `FinancialRecord`.

Reports use `reportType` to describe their subject or purpose. Financial records use `recordType` to distinguish document and transaction types. Relationships capture project context, participating organizations and references between records.

See the [model reference](model/README.md) for the schema and its representations.
