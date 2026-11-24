# Knowledge graph model

A structured model for projects, organizations, documents, reports and financial records. [model.tsv](model.tsv) records the complete property and relationship definitions.

## Node labels

Every node requires a stable string `id`. `Project` and `Organization` also require `name`. `Report` requires `reportType`; `FinancialRecord` requires `recordType`. All other properties are optional. Every label except `Project` and `Organization` supports `sourceUrl` for genuine original provenance.

| Label | Meaning |
|---|---|
| `Project` | Construction project and its context. |
| `Organization` | Company or public body; project participation is expressed through relationships. |
| `Letter` | Project correspondence with printed references, names and provenance. |
| `EOTClaim` | Extension-of-time claim; contract baselines remain claim snapshots. |
| `Agreement` | Signed agreement and clause reference. |
| `Proposal` | Project bid or proposal. |
| `Drawing` | Individual drawing sheet. |
| `BOQ` | Independently represented priced bill of quantities at total level. |
| `Schedule` | Programme of works with its status/data date. |
| `Report` | Individual project or organizational report, classified by `reportType`. |
| `FinancialRecord` | Individual financial document, transaction, obligation, allocation or reporting record, classified by `recordType`. |

Full property names, types, required flags, descriptions and model settings are recorded in [model.tsv](model.tsv). The sections below highlight the changes from the previous local model.

## Report

`reportType` is an open string classification. Examples include `ProgressReport`, `TechnicalReport`, `MonthlyReport`, `WeeklyReport`, `InspectionReport`, `SiteReport`, `SafetyReport`, `EnvironmentalReport` and `FinancialReport`; these examples are not a closed enum or additional labels.

| Properties | Type / meaning |
|---|---|
| `reportType` | Required string identifying the report's nature. |
| `referenceNumber`, `referenceNumberNorm` | Original reference and its derived normalized form. |
| `title`, `revision`, `status` | Source-supported report identity and state. |
| `reportDate` | Issue date (`DATETIME`). |
| `periodStart`, `periodEnd` | Reporting-period dates (`DATETIME`). |
| `plannedTotal`, `executedTotal` | Floating-point progress measurements, only when applicable and evidenced. |
| `unit` | String describing applicable measurements; The model does not specify a closed enum. |
| `summary`, `summaryEmbedding` | Exact factual summary and its matching complete embedding. |

Reports reconcile using type, original/normalized reference, title, project, preparing organization, issue date, reporting period, revision and provenance. Distinguish revisions, different reporting periods and independently issued reports. Both permitted relationships are optional.

## FinancialRecord

The required `recordType` enum is `Invoice`, `Payment`, `Payroll`, `Expense`, `Cost`, `Budget`, `CreditNote`, `FinancialStatement`, `PurchaseOrder`, `Receipt` or `Other`. Each uses the single `FinancialRecord` label. `category` describes financial classification separately from record type.

| Properties | Type / meaning |
|---|---|
| `recordType` | Required string from the closed enum above. |
| `referenceNumber`, `referenceNumberNorm` | Original reference and its derived normalized form. |
| `description`, `category`, `status` | Source-supported description, financial classification and state. |
| `amount`, `currency` | Primary source-reported amount (`FLOAT`) and explicit uppercase ISO 4217 currency (`STRING`). |
| `taxAmount`, `includesVAT` | Evidenced tax amount (`FLOAT`) and VAT inclusion (`BOOLEAN`). |
| `effectiveDate`, `dueDate` | Relevant event and due dates (`DATETIME`). |
| `periodStart`, `periodEnd` | Applicable financial/reporting period (`DATETIME`). |
| `paymentMethod`, `transactionReference`, `paymentTerms` | Optional strings applicable to the record. |
| `interimNumber` | Optional integer payment sequence, at least 1. |
| `grossAmount`, `netAmount`, `deductions` | Separate evidenced floating-point amounts. |
| `costType`, `costCenter`, `fiscalYear` | Cost classification strings and integer financial year. |
| `revisedAmount`, `adjustmentReason` | Evidenced revised amount (`FLOAT`) and reason (`STRING`). |
| `statementType` | Optional financial statement classification string. |
| `summary`, `summaryEmbedding` | Exact factual summary and its matching complete embedding. |

Populate type-specific properties only when applicable and evidenced. Keep invoiced, paid, incurred, allocated, gross and net amounts distinct. Reconcile identity using record type, references, amount, currency, dates, status, provenance and independently resolved Organization/Project context. Similarity nominates candidates; corroborating facts establish identity.

## Permitted relationships

The model has 14 relationship types and 23 source/target patterns. Relationships are optional with no cardinality rules. Each endpoint must be independently resolved from evidence.

| Type | Source → target | Optional relationship properties |
|---|---|---|
| `FOR_PROJECT` | BOQ, Letter, Drawing, Agreement, Schedule, Report, EOTClaim, Proposal or FinancialRecord → Project | None |
| `CLIENT_OF` | Organization → Project | None |
| `CONTRACTOR_OF` | Organization → Project | None |
| `CONSULTANT_OF` | Organization → Project | `role`: Supervision, Design, Design and Supervision, Project Management |
| `SENT_BY` | Letter → Organization | None |
| `ADDRESSED_TO` | Letter → Organization | None |
| `SUBMITTED_BY` | EOTClaim or Proposal → Organization | None |
| `DESIGNED_BY` | Drawing → Organization | None |
| `SIGNED_BY` | Agreement → Organization | None |
| `CITES` | EOTClaim → Agreement | None |
| `PREPARED_BY` | Report → Organization | None |
| `INVOLVES` | FinancialRecord → Organization | `role`: Issuer, Recipient, Payer, Payee, Beneficiary, Contractor |
| `REFERENCED_IN` | FinancialRecord → Letter | None |
| `GOVERNED_BY` | FinancialRecord → Agreement | None |

Reports support only `FOR_PROJECT` and `PREPARED_BY`. Financial records support only `FOR_PROJECT`, `INVOLVES`, `REFERENCED_IN` and `GOVERNED_BY`. The model excludes additional financial labels, `FinancialLineItem`, and relationships such as `HAS_FINANCIAL_RECORD`, `SETTLES`, `DERIVED_FROM`, `HAS_LINE_ITEM` and `ALLOCATED_TO`. `BOQ` remains independent.

## Summary and embedding fields

`Project`, `Letter`, `EOTClaim`, `Agreement`, `Proposal`, `Report` and `FinancialRecord` support `summary` and `summaryEmbedding`. The text and vector form a matching pair: the vector represents the exact stored summary. Embedding model and dimension settings are recorded in `model.tsv`.

Retain original references and derive normalized references by upper-casing and retaining only ASCII `A-Z` and `0-9`. Preserve zeros, false values, stable IDs, unrelated stored information and provenance. Missing or invalid input is an absent update, not a request to clear stored values.

## Legacy reconciliation

`ProgressReport` becomes `Report` with `reportType=ProgressReport`, retaining its ID, source URL, properties and verified project context. `Payment` becomes `FinancialRecord` with `recordType=Payment`: `amountPaid` maps to `amount` and `paidDate` to `effectiveDate`; preserve its ID, provenance, interim number, currency and VAT flag. Resolve any new relationships independently. These are schema mappings, not automatically executed database changes.

The earlier TSV and superseded CSV headers are retained under [archive/model/pre-instruction-v2/](../archive/model/pre-instruction-v2/). The four earlier Turtle files and their consolidated comparison are historical snapshots under [archive/ontologies/](../archive/ontologies/).

## Local representations

| File | What it is |
|---|---|
| `model.tsv` | Structured model: labels, properties, relationships, required flags and closed enums. Search roles and index settings preserve the repository's existing retrieval conventions; they are local representation metadata. |
| `templates/nodes/*.csv`, `templates/relationships/*.csv` | Empty CSVs with the columns to fill. Lists go in one cell separated by `\|`. Dates are `yyyy-mm-dd` (stored as DATETIME, midnight UTC) or full ISO datetimes. Types with several source labels get one file per source, e.g. `FOR_PROJECT__Letter.csv`. |
| `import.cypher` | Reference for indexes, CSV loading and type conversion. |
| `retrieval.cypher` | Query patterns for agents: weighted hybrid (Lucene + vector), fuzzy name/alias (APOC Levenshtein), exact reference lookup, and project-scoped hybrid. |
| `model.json` | Data Importer-compatible representation, format 3.0.0: labels, types, `id` key constraints and CSV mappings. |
| `post_import.cypher` | Run once after loading data through Neo4j Import. It creates the search indexes and the `…Norm` reference copies, which Data Importer can't make. |
| `ontology.ttl` | Current model as OWL/Turtle in Fabric's export style. The filename and `owl:versionInfo` are retained generator metadata; refer to the structured schema for the current model. Lists appear as text, embedding properties are omitted, and relationship properties appear in comments. |
| `import_csv/*.csv` | Flat copies of the current empty node and relationship headers, matching the importer model. |
| `generate.py` | Local artifact generator. |
| [`../diagram/*.mmd`](../diagram/) | Generated Mermaid relationship overview and complete graph schema with typed properties. |

## Search roles (`search` column)

| Role | Meaning | Implemented by |
|---|---|---|
| `key` | Unique identifier | uniqueness constraint |
| `fuzzy` | Names and aliases, partial or misspelt | `apoc.text.levenshteinSimilarity` (+ `CONTAINS` for 4+ characters) |
| `lucene` | Keyword search on text | full-text index `<label>_text` |
| `semantic` | Meaning-based search on `summary` | vector index `<label>_summary_embedding` |
| `exact` | Codes and numbers | range index; `…Norm` copies are upper-cased with separators removed |
| `filter` / `range` | Allowed-value fields / dates and amounts | `WHERE` clauses (allowed-value fields are indexed) |
| `context` | `sourceUrl`, for the agent to cite or open | not searched |

## Import representations

The CSV headers, importer metadata and Cypher files are reference representations of the model. They describe data shape and indexing; identity reconciliation and provenance remain separate concerns.

## Refreshing local artifacts

After updating `model.tsv`, run `python3 model/generate.py` from the repository root. This updates the grouped templates, importer JSON, Cypher references, generated Turtle and Mermaid diagrams locally. Refresh the flat `import_csv/` headers from the grouped templates as well. Preserve populated CSVs before refreshing headers, and retire superseded node headers explicitly: the existing generator removes obsolete relationship templates but does not remove obsolete node templates. Refreshing local files does not apply database changes.

## Additional domains

Add rows to `model.tsv` with a new `domain` value. Reuse `Project` and `Organization` instead of redefining them, and don't give an existing label name a different meaning.

## Agent access (MCP)

See [MCP.md](../integrations/neo4j/MCP.md): how to run, register and test the Neo4j MCP server.
