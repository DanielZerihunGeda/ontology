# Graph schema diagrams

Mermaid diagrams generated from [the structured schema](../model/model.tsv), checked against the Model section of [instruction-v2.md](../instructions/instruction-v2.md):

| Diagram | Contents |
|---|---|
| [overview.mmd](overview.mmd) | Flowchart with all 11 node labels, all 141 typed node properties, required flags, 23 directed source/target patterns and optional relationship properties. |
| [graph-schema.mmd](graph-schema.mmd) | Class diagram of the same complete schema, with notes for required fields and closed enums. |

Open either `.mmd` file with a Mermaid preview, or copy its contents into a `mermaid` fenced code block in a Markdown viewer that supports Mermaid.

Arrows run from source to target. Relationships are optional; the schema defines no cardinality rules. Boxes represent graph node labels. The flowchart marks required properties with `!`, following instruction-v2.md. The class diagram lists required fields in class notes and uses `LIST~STRING~` and `LIST~FLOAT~` for list types. All other properties are optional. `id` is a unique string key for each node label.

`CONSULTANT_OF.role` and `INVOLVES.role` are optional relationship properties shown on their arrows. Their allowed values appear in the class diagram's `Project` and `Organization` notes, respectively. Document nodes support optional `sourceUrl` provenance. `Report.reportType` is an open string classification; `FinancialRecord.recordType` uses the closed enum shown in its note.

For `Project`, `Letter`, `EOTClaim`, `Agreement`, `Proposal`, `Report` and `FinancialRecord`, `summary` and `summaryEmbedding` form an inseparable pair when stored. The vector represents the exact summary text using `text-embedding-3-small` with 1536 dimensions. Normalized references retain only uppercase ASCII `A-Z` and `0-9`. See [instruction-v2.md](../instructions/instruction-v2.md) for the complete validation and persistence rules.

To refresh the diagrams after editing the schema, run from the repository root:

```sh
python3 model/generate.py
```

This also refreshes the existing model artifacts. See the [artifact refresh guidance](../model/README.md#refreshing-local-artifacts) before running it if CSV templates contain data.
