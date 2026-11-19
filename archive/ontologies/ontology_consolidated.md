# Reference Ontology — consolidated view

> Historical comparison of the four earlier ontology snapshots. The current model is recorded in [model/model.tsv](../../model/model.tsv). See the [current model reference](../../model/README.md) for `Report`, `FinancialRecord` and their permitted relationships. The older labels and directions below belong to the compared snapshots.

Sources (all share namespace `https://example.org/ontology#`):

| File | Label | Style | Relationships |
|---|---|---|---|
| `archive/ontologies/schema_v0_2.ttl` | Reference KG Schema v0.2 | hand-written OWL, enums, unions | none |
| `archive/ontologies/schema_v0_4.ttl` | Reference KG Schema v0.4 | same + `designer`, comments | single `belongsToProject` (all → Project) |
| `archive/ontologies/ontology.ttl` | Ontology_1 | Fabric export | 14 named edges, mixed directions |
| `archive/ontologies/Engineering_ontology.ttl` | Engineering ontology | Fabric export, extended | 18 named edges + `Proposal` class |

v0.2 is a strict subset of v0.4, so v0.4 stands for "Reference" below.

Attribute markers in the class diagram: no marker = in both Reference and Fabric ·
`†` = Reference v0.4 only · `‡` = Fabric only (mostly Engineering) ·
`§` = Ontology_1 + Reference but dropped in Engineering.

## 1. Consolidated class diagram (union of all files)

```mermaid
classDiagram
direction LR

class Project {
  +string name †
  +string location †
  +int durationDays §
  +string projectId ‡
  +string ProjectName ‡
  +string address ‡
  +string projectDescription ‡
  +string projectStatus ‡
  +string projectAreaSqm ‡
  +dateTime startDate ‡
  +string plannedCompletionDate ‡
  +dateTime actualCompletionDate ‡
  +int projectDurationDays ‡
}
class Client {
  +string name †
  +string alias †
  +ClientTypeValue clientType
  +string clientId ‡
  +string legalName ‡
  +string address ‡
  +string city ‡
  +string country ‡
  +string email ‡
  +string phoneNumber ‡
  +string taxIdentificationNumber ‡
  +dateTime createdAt ‡
}
class MainContractor {
  <<Reference only>>
  +string name
  +string alias
  +string location
  +string address
}
class Subcontractor {
  +string name †
  +string alias †
  +string location †
  +string address †
}
class Consultant {
  +string name †
  +string alias †
  +ConsultantRoleValue consultantRole
}
class BOQ {
  +decimal boqTotalAmount
  +date boqDate
  +string currency †
  +boolean includesVAT †
}
class Payment {
  +positiveInt interimNumber
  +date paymentDate
  +decimal amountPaid
  +string currency †
  +boolean includesVAT †
  +string paymentId ‡
}
class Letter {
  +string letterReference
  +date letterDate
  +LetterDirectionValue direction
  +string subject
  +string sender
  +string recipient §
  +string summary ‡
}
class Drawing {
  +string designer
  +string drawingNumber
  +string drawingTitle
  +DrawingDisciplineValue discipline
  +string revision †
  +date issueDate
  +string drawingReference ‡
}
class AgreementClause {
  +date agreementDate
  +string mainContractorWitness
  +string subcontractorWitness
  +string clauseNumber
  +date clauseDate
  +anyURI clauseLink †
}
class Schedule {
  +date dataDate
  +date plannedStartDate
  +date plannedFinishDate
  +string revision †
  +string scheduleId ‡
  +string taskName ‡
  +string taskSummary ‡
}
class ProgressReport {
  +date reportDate
  +decimal plannedTotal
  +decimal executedTotal
  +ProgressUnitValue progressUnit
}
class EOTClaim {
  +date claimDate
  +date contractSigningDate
  +date siteHandoverDate
  +date commencementDate
  +decimal originalContractPriceInclVAT
  +int contractDurationDays
  +date originalCompletionDate
  +int previouslyApprovedEOTDays
  +int requestedEOTDays
  +date revisedCompletionDate
  +string keyTakeaways
  +string currency †
  +anyURI clauseLink †
  +string clauseReference ‡
  +string clauseSummary ‡
}
class Proposal {
  <<Engineering only>>
  +string bidId
  +string bidReferenceNumber
  +string bidTitle
  +string bidStatus
  +dateTime bidValidityDate
  +dateTime submissionDate
  +dateTime lastModifiedAt
  +string proposedAmount
  +string currency
  +string proposalSummary
}

class ClientTypeValue {
  <<enumeration>>
  Government
  Public Enterprise
  Private
  NGO / International Organization
  Individual
}
class ConsultantRoleValue {
  <<enumeration>>
  Supervision
  Design
  Design and Supervision
  Project Management
}
class LetterDirectionValue {
  <<enumeration>>
  Incoming
  Outgoing
}
class DrawingDisciplineValue {
  <<enumeration>>
  Architectural
  Structural
  Civil Engineering
  Mechanical
  Plumbing
  Interior Design
  Geotechnical
  Electrical
  Infrastructure
}
class ProgressUnitValue {
  <<enumeration>>
  Percent
  Amount
}

%% Project hub (Reference: belongsToProject from every class; Fabric: named edges)
Project --> Client : HAS_CLIENT
Project --> Consultant : HAS_CONSULTANT
Project --> Subcontractor : HAS_CONTRACTOR
Project --> Drawing : HAS_DRAWING
Project --> Letter : HAS_LETTER
Project --> Schedule : HAS_SCHEDULE
Project --> ProgressReport : HAS_PROGRESS_REPORT
Project --> AgreementClause : BELONGS_TO_2
BOQ --> Project : BELONGS_TO
EOTClaim --> Project : BELONGS_TO_3
Payment --> Project : BELONGS_TO_4
Proposal --> Project : BELONGS_TO_5
MainContractor --> Project : belongsToProject

%% Cross-entity edges (Fabric only)
Letter --> Client : DELIVERED_TO / DELIEVERED_BY
Letter --> Consultant : DELIVERED_TO / DELIEVERED_BY
Letter --> Subcontractor : DELIVERED_TO / DELIEVERED_BY
EOTClaim --> Subcontractor : SUBMITTED_BY_2

%% Controlled vocabularies (Reference only; Fabric uses plain string)
Client ..> ClientTypeValue
Consultant ..> ConsultantRoleValue
Letter ..> LetterDirectionValue
Drawing ..> DrawingDisciplineValue
ProgressReport ..> ProgressUnitValue
```

Not drawn: `kg:identifier` (Reference, no domain — applies to every class).

## 2. How each file represents relationships

### Reference v0.4 — pure star, one predicate

```mermaid
flowchart LR
  P((Project))
  BOQ & Client & MainContractor & Subcontractor & Consultant & Payment & Letter & Drawing & AgreementClause & Schedule & ProgressReport & EOTClaim -- belongsToProject --> P
```

### Ontology_1 (`archive/ontologies/ontology.ttl`) — named edges, inconsistent direction

```mermaid
flowchart LR
  P((Project))
  BOQ -- BELONGS_TO --> P
  P -- "BELONGS_TO_2 ⚠ reversed" --> AgreementClause
  EOTClaim -- BELONGS_TO_3 --> P
  Payment -- BELONGS_TO_4 --> P
  Consultant -- "HAS_CONSULTANT ⚠ reversed" --> P
  ProgressReport -- "HAS_PROGRESS_REPORT ⚠ reversed" --> P
  P -- HAS_DRAWING --> Drawing
  P -- HAS_SCHEDULE --> Schedule
  EOTClaim -- SUBMITTED_BY_2 --> Subcontractor
  Letter -- DELIVERED_TO --> Consultant
  Letter -- DELIVERED_TO_2 --> Client
  Letter -- DELIVERED_TO_3 --> Subcontractor
  Letter -- DELIEVERED_BY_2 --> Consultant
  Letter -- DELIEVERED_BY_3 --> Subcontractor
  Letter -- DELIEVERED_BY_5 --> Client
```

Client and Letter have no path to Project; there is no MainContractor class.

### Engineering (`archive/ontologies/Engineering_ontology.ttl`) — Ontology_1 fixed and extended

```mermaid
flowchart LR
  P((Project))
  P -- HAS_CLIENT --> Client
  P -- HAS_CONSULTANT --> Consultant
  P -- HAS_CONTRACTOR --> Subcontractor
  P -- HAS_DRAWING --> Drawing
  P -- HAS_LETTER --> Letter
  P -- HAS_SCHEDULE --> Schedule
  P -- HAS_PROGRESS_REPORT --> ProgressReport
  P -- "BELONGS_TO_2 ⚠ still reversed" --> AgreementClause
  BOQ -- BELONGS_TO --> P
  EOTClaim -- BELONGS_TO_3 --> P
  Payment -- BELONGS_TO_4 --> P
  Proposal -- BELONGS_TO_5 --> P
  EOTClaim -- SUBMITTED_BY_2 --> Subcontractor
  Letter -- "DELIVERED_TO / _2 / _3" --> Consultant & Client & Subcontractor
  Letter -- "DELIEVERED_BY_2 / _3 / _5" --> Consultant & Subcontractor & Client
```

## 3. Differences worth fixing

- **Direction is mixed.** `HAS_*` points Project → X; `BELONGS_TO*` points X → Project, except `BELONGS_TO_2`, which points Project → AgreementClause. Pick one direction.
- **Numbered predicate names** (`BELONGS_TO_2…5`, `DELIVERED_TO_2/3`) are Fabric artefacts of one predicate per domain/range pair. Each set is really one property with a union range.
- **Typo:** `DELIEVERED_BY_*` should be `DELIVERED_BY`.
- **MainContractor** exists only in Reference. Fabric's `HAS_CONTRACTOR` points to `Subcontractor`.
- **Enums lost in Fabric.** clientType, consultantRole, direction, discipline and progressUnit are plain `xsd:string` there.
- **Types drift.** Reference uses `xsd:date`; Fabric uses `xsd:dateTime`. Ontology_1 stores day counts and `interimNumber` as strings; Engineering fixes the day counts but `interimNumber`, `projectAreaSqm`, `proposedAmount` and `plannedCompletionDate` are still strings.
- **Semantic drift.** In Engineering, `fabric:clientType` is labelled `industrySector`. `letterReference` is redefined as a link to the document, not the reference number.
- **Duplicates.** Project has `durationDays` (Reference / Ontology_1) and `projectDurationDays` (Engineering), `name` and `ProjectName`. EOTClaim has `clauseLink` (Reference) and `clauseReference` (Engineering).
- **Dropped in Engineering:** `Letter.recipient` and `Project.durationDays`.
- **Reference-only shared properties:** identifier, name, alias, location, currency, includesVAT, clauseLink and revision.
