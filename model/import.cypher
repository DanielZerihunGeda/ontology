// =====================================================================
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
// Lists (aliases, names, embeddings) go in one cell separated by '|'.
// Dates are ISO yyyy-mm-dd (stored as DATETIME at 00:00 UTC) or full ISO datetimes. Empty cells are stored as missing properties.
// Re-running is safe: nodes and relationships are MERGEd on id.
// =====================================================================

// ---------------------------------------------------------------- uniqueness
CREATE CONSTRAINT project_id IF NOT EXISTS FOR (n:Project) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT organization_id IF NOT EXISTS FOR (n:Organization) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT letter_id IF NOT EXISTS FOR (n:Letter) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT eot_claim_id IF NOT EXISTS FOR (n:EOTClaim) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT agreement_id IF NOT EXISTS FOR (n:Agreement) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT proposal_id IF NOT EXISTS FOR (n:Proposal) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT drawing_id IF NOT EXISTS FOR (n:Drawing) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT financial_record_id IF NOT EXISTS FOR (n:FinancialRecord) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT boq_id IF NOT EXISTS FOR (n:BOQ) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT schedule_id IF NOT EXISTS FOR (n:Schedule) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT report_id IF NOT EXISTS FOR (n:Report) REQUIRE n.id IS UNIQUE;

// ---------------------------------------------------------------- exact-match lookups
CREATE INDEX organization_tax_id IF NOT EXISTS FOR (n:Organization) ON (n.taxId);
CREATE INDEX letter_reference_number IF NOT EXISTS FOR (n:Letter) ON (n.referenceNumber);
CREATE INDEX letter_reference_number_norm IF NOT EXISTS FOR (n:Letter) ON (n.referenceNumberNorm);
CREATE INDEX agreement_clause_number IF NOT EXISTS FOR (n:Agreement) ON (n.clauseNumber);
CREATE INDEX agreement_clause_number_norm IF NOT EXISTS FOR (n:Agreement) ON (n.clauseNumberNorm);
CREATE INDEX proposal_reference_number IF NOT EXISTS FOR (n:Proposal) ON (n.referenceNumber);
CREATE INDEX proposal_reference_number_norm IF NOT EXISTS FOR (n:Proposal) ON (n.referenceNumberNorm);
CREATE INDEX drawing_reference_number IF NOT EXISTS FOR (n:Drawing) ON (n.referenceNumber);
CREATE INDEX drawing_reference_number_norm IF NOT EXISTS FOR (n:Drawing) ON (n.referenceNumberNorm);
CREATE INDEX drawing_revision IF NOT EXISTS FOR (n:Drawing) ON (n.revision);
CREATE INDEX financial_record_reference_number IF NOT EXISTS FOR (n:FinancialRecord) ON (n.referenceNumber);
CREATE INDEX financial_record_reference_number_norm IF NOT EXISTS FOR (n:FinancialRecord) ON (n.referenceNumberNorm);
CREATE INDEX financial_record_transaction_reference IF NOT EXISTS FOR (n:FinancialRecord) ON (n.transactionReference);
CREATE INDEX financial_record_interim_number IF NOT EXISTS FOR (n:FinancialRecord) ON (n.interimNumber);
CREATE INDEX schedule_revision IF NOT EXISTS FOR (n:Schedule) ON (n.revision);
CREATE INDEX report_reference_number IF NOT EXISTS FOR (n:Report) ON (n.referenceNumber);
CREATE INDEX report_reference_number_norm IF NOT EXISTS FOR (n:Report) ON (n.referenceNumberNorm);
CREATE INDEX report_revision IF NOT EXISTS FOR (n:Report) ON (n.revision);

// ---------------------------------------------------------------- controlled-value filters
// Dates/amounts are left unindexed: queries usually start from a Project and walk FOR_PROJECT.
CREATE INDEX project_status IF NOT EXISTS FOR (n:Project) ON (n.status);
CREATE INDEX organization_client_type IF NOT EXISTS FOR (n:Organization) ON (n.clientType);
CREATE INDEX letter_direction IF NOT EXISTS FOR (n:Letter) ON (n.direction);
CREATE INDEX eot_claim_status IF NOT EXISTS FOR (n:EOTClaim) ON (n.status);
CREATE INDEX proposal_status IF NOT EXISTS FOR (n:Proposal) ON (n.status);
CREATE INDEX drawing_discipline IF NOT EXISTS FOR (n:Drawing) ON (n.discipline);
CREATE INDEX financial_record_record_type IF NOT EXISTS FOR (n:FinancialRecord) ON (n.recordType);

// ---------------------------------------------------------------- full-text (Lucene)
// Query: CALL db.index.fulltext.queryNodes('<index>', $text) YIELD node, score
CREATE FULLTEXT INDEX project_text IF NOT EXISTS FOR (n:Project) ON EACH [n.summary];
CREATE FULLTEXT INDEX letter_text IF NOT EXISTS FOR (n:Letter) ON EACH [n.subject, n.summary];
CREATE FULLTEXT INDEX eot_claim_text IF NOT EXISTS FOR (n:EOTClaim) ON EACH [n.summary];
CREATE FULLTEXT INDEX agreement_text IF NOT EXISTS FOR (n:Agreement) ON EACH [n.summary];
CREATE FULLTEXT INDEX proposal_text IF NOT EXISTS FOR (n:Proposal) ON EACH [n.title, n.summary];
CREATE FULLTEXT INDEX drawing_text IF NOT EXISTS FOR (n:Drawing) ON EACH [n.title];
CREATE FULLTEXT INDEX financial_record_text IF NOT EXISTS FOR (n:FinancialRecord) ON EACH [n.description, n.summary];
CREATE FULLTEXT INDEX report_text IF NOT EXISTS FOR (n:Report) ON EACH [n.title, n.summary];

// ---------------------------------------------------------------- vector (text-embedding-3-small, 1536 dims, cosine)
// Query: CALL db.index.vector.queryNodes('<index>', $k, $embedding) YIELD node, score
CREATE VECTOR INDEX project_summary_embedding IF NOT EXISTS FOR (n:Project) ON (n.summaryEmbedding)
  OPTIONS { indexConfig: { `vector.dimensions`: 1536, `vector.similarity_function`: 'cosine' } };
CREATE VECTOR INDEX letter_summary_embedding IF NOT EXISTS FOR (n:Letter) ON (n.summaryEmbedding)
  OPTIONS { indexConfig: { `vector.dimensions`: 1536, `vector.similarity_function`: 'cosine' } };
CREATE VECTOR INDEX eot_claim_summary_embedding IF NOT EXISTS FOR (n:EOTClaim) ON (n.summaryEmbedding)
  OPTIONS { indexConfig: { `vector.dimensions`: 1536, `vector.similarity_function`: 'cosine' } };
CREATE VECTOR INDEX agreement_summary_embedding IF NOT EXISTS FOR (n:Agreement) ON (n.summaryEmbedding)
  OPTIONS { indexConfig: { `vector.dimensions`: 1536, `vector.similarity_function`: 'cosine' } };
CREATE VECTOR INDEX proposal_summary_embedding IF NOT EXISTS FOR (n:Proposal) ON (n.summaryEmbedding)
  OPTIONS { indexConfig: { `vector.dimensions`: 1536, `vector.similarity_function`: 'cosine' } };
CREATE VECTOR INDEX financial_record_summary_embedding IF NOT EXISTS FOR (n:FinancialRecord) ON (n.summaryEmbedding)
  OPTIONS { indexConfig: { `vector.dimensions`: 1536, `vector.similarity_function`: 'cosine' } };
CREATE VECTOR INDEX report_summary_embedding IF NOT EXISTS FOR (n:Report) ON (n.summaryEmbedding)
  OPTIONS { indexConfig: { `vector.dimensions`: 1536, `vector.similarity_function`: 'cosine' } };

// ---------------------------------------------------------------- nodes
LOAD CSV WITH HEADERS FROM $baseUrl + 'nodes/Project.csv' AS row
WITH row WHERE NOT (row.id IS NULL OR trim(row.id) = '')
CALL (row) {
  MERGE (n:Project {id: trim(row.id)})
  SET n += {
    name: CASE WHEN (row.name IS NULL OR trim(row.name) = '') THEN null ELSE trim(row.name) END,
    aliases: CASE WHEN (row.aliases IS NULL OR trim(row.aliases) = '') THEN null ELSE [x IN split(trim(row.aliases), '|') WHERE trim(x) <> '' | trim(x)] END,
    summary: CASE WHEN (row.summary IS NULL OR trim(row.summary) = '') THEN null ELSE trim(row.summary) END,
    summaryEmbedding: CASE WHEN (row.summaryEmbedding IS NULL OR trim(row.summaryEmbedding) = '') THEN null ELSE [x IN split(trim(row.summaryEmbedding), '|') | toFloat(x)] END,
    status: CASE WHEN (row.status IS NULL OR trim(row.status) = '') THEN null ELSE trim(row.status) END,
    location: CASE WHEN (row.location IS NULL OR trim(row.location) = '') THEN null ELSE trim(row.location) END,
    startDate: CASE WHEN (row.startDate IS NULL OR trim(row.startDate) = '') THEN null ELSE datetime(trim(row.startDate)) END,
    plannedCompletionDate: CASE WHEN (row.plannedCompletionDate IS NULL OR trim(row.plannedCompletionDate) = '') THEN null ELSE datetime(trim(row.plannedCompletionDate)) END,
    actualCompletionDate: CASE WHEN (row.actualCompletionDate IS NULL OR trim(row.actualCompletionDate) = '') THEN null ELSE datetime(trim(row.actualCompletionDate)) END,
    durationDays: CASE WHEN (row.durationDays IS NULL OR trim(row.durationDays) = '') THEN null ELSE toInteger(trim(row.durationDays)) END,
    areaSqm: CASE WHEN (row.areaSqm IS NULL OR trim(row.areaSqm) = '') THEN null ELSE toFloat(trim(row.areaSqm)) END
  }
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'nodes/Organization.csv' AS row
WITH row WHERE NOT (row.id IS NULL OR trim(row.id) = '')
CALL (row) {
  MERGE (n:Organization {id: trim(row.id)})
  SET n += {
    name: CASE WHEN (row.name IS NULL OR trim(row.name) = '') THEN null ELSE trim(row.name) END,
    aliases: CASE WHEN (row.aliases IS NULL OR trim(row.aliases) = '') THEN null ELSE [x IN split(trim(row.aliases), '|') WHERE trim(x) <> '' | trim(x)] END,
    clientType: CASE WHEN (row.clientType IS NULL OR trim(row.clientType) = '') THEN null ELSE trim(row.clientType) END,
    address: CASE WHEN (row.address IS NULL OR trim(row.address) = '') THEN null ELSE trim(row.address) END,
    city: CASE WHEN (row.city IS NULL OR trim(row.city) = '') THEN null ELSE trim(row.city) END,
    country: CASE WHEN (row.country IS NULL OR trim(row.country) = '') THEN null ELSE trim(row.country) END,
    email: CASE WHEN (row.email IS NULL OR trim(row.email) = '') THEN null ELSE trim(row.email) END,
    phoneNumber: CASE WHEN (row.phoneNumber IS NULL OR trim(row.phoneNumber) = '') THEN null ELSE trim(row.phoneNumber) END,
    taxId: CASE WHEN (row.taxId IS NULL OR trim(row.taxId) = '') THEN null ELSE trim(row.taxId) END
  }
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'nodes/Letter.csv' AS row
WITH row WHERE NOT (row.id IS NULL OR trim(row.id) = '')
CALL (row) {
  MERGE (n:Letter {id: trim(row.id)})
  SET n += {
    referenceNumber: CASE WHEN (row.referenceNumber IS NULL OR trim(row.referenceNumber) = '') THEN null ELSE trim(row.referenceNumber) END,
    referenceNumberNorm: CASE WHEN (row.referenceNumber IS NULL OR trim(row.referenceNumber) = '') THEN null ELSE reduce(s = '', c IN split(toUpper(row.referenceNumber), '') | s + CASE WHEN c =~ '[A-Z0-9]' THEN c ELSE '' END) END,
    issueDate: CASE WHEN (row.issueDate IS NULL OR trim(row.issueDate) = '') THEN null ELSE datetime(trim(row.issueDate)) END,
    direction: CASE WHEN (row.direction IS NULL OR trim(row.direction) = '') THEN null ELSE trim(row.direction) END,
    subject: CASE WHEN (row.subject IS NULL OR trim(row.subject) = '') THEN null ELSE trim(row.subject) END,
    summary: CASE WHEN (row.summary IS NULL OR trim(row.summary) = '') THEN null ELSE trim(row.summary) END,
    summaryEmbedding: CASE WHEN (row.summaryEmbedding IS NULL OR trim(row.summaryEmbedding) = '') THEN null ELSE [x IN split(trim(row.summaryEmbedding), '|') | toFloat(x)] END,
    senderName: CASE WHEN (row.senderName IS NULL OR trim(row.senderName) = '') THEN null ELSE trim(row.senderName) END,
    recipientNames: CASE WHEN (row.recipientNames IS NULL OR trim(row.recipientNames) = '') THEN null ELSE [x IN split(trim(row.recipientNames), '|') WHERE trim(x) <> '' | trim(x)] END,
    sourceUrl: CASE WHEN (row.sourceUrl IS NULL OR trim(row.sourceUrl) = '') THEN null ELSE trim(row.sourceUrl) END
  }
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'nodes/EOTClaim.csv' AS row
WITH row WHERE NOT (row.id IS NULL OR trim(row.id) = '')
CALL (row) {
  MERGE (n:EOTClaim {id: trim(row.id)})
  SET n += {
    submittedDate: CASE WHEN (row.submittedDate IS NULL OR trim(row.submittedDate) = '') THEN null ELSE datetime(trim(row.submittedDate)) END,
    status: CASE WHEN (row.status IS NULL OR trim(row.status) = '') THEN null ELSE trim(row.status) END,
    summary: CASE WHEN (row.summary IS NULL OR trim(row.summary) = '') THEN null ELSE trim(row.summary) END,
    summaryEmbedding: CASE WHEN (row.summaryEmbedding IS NULL OR trim(row.summaryEmbedding) = '') THEN null ELSE [x IN split(trim(row.summaryEmbedding), '|') | toFloat(x)] END,
    contractSigningDate: CASE WHEN (row.contractSigningDate IS NULL OR trim(row.contractSigningDate) = '') THEN null ELSE datetime(trim(row.contractSigningDate)) END,
    siteHandoverDate: CASE WHEN (row.siteHandoverDate IS NULL OR trim(row.siteHandoverDate) = '') THEN null ELSE datetime(trim(row.siteHandoverDate)) END,
    commencementDate: CASE WHEN (row.commencementDate IS NULL OR trim(row.commencementDate) = '') THEN null ELSE datetime(trim(row.commencementDate)) END,
    originalContractPrice: CASE WHEN (row.originalContractPrice IS NULL OR trim(row.originalContractPrice) = '') THEN null ELSE toFloat(trim(row.originalContractPrice)) END,
    currency: CASE WHEN (row.currency IS NULL OR trim(row.currency) = '') THEN null ELSE trim(row.currency) END,
    includesVAT: CASE WHEN (row.includesVAT IS NULL OR trim(row.includesVAT) = '') THEN null ELSE toBoolean(trim(row.includesVAT)) END,
    originalDurationDays: CASE WHEN (row.originalDurationDays IS NULL OR trim(row.originalDurationDays) = '') THEN null ELSE toInteger(trim(row.originalDurationDays)) END,
    originalCompletionDate: CASE WHEN (row.originalCompletionDate IS NULL OR trim(row.originalCompletionDate) = '') THEN null ELSE datetime(trim(row.originalCompletionDate)) END,
    previouslyApprovedExtensionDays: CASE WHEN (row.previouslyApprovedExtensionDays IS NULL OR trim(row.previouslyApprovedExtensionDays) = '') THEN null ELSE toInteger(trim(row.previouslyApprovedExtensionDays)) END,
    requestedExtensionDays: CASE WHEN (row.requestedExtensionDays IS NULL OR trim(row.requestedExtensionDays) = '') THEN null ELSE toInteger(trim(row.requestedExtensionDays)) END,
    requestedCompletionDate: CASE WHEN (row.requestedCompletionDate IS NULL OR trim(row.requestedCompletionDate) = '') THEN null ELSE datetime(trim(row.requestedCompletionDate)) END,
    approvedExtensionDays: CASE WHEN (row.approvedExtensionDays IS NULL OR trim(row.approvedExtensionDays) = '') THEN null ELSE toInteger(trim(row.approvedExtensionDays)) END,
    sourceUrl: CASE WHEN (row.sourceUrl IS NULL OR trim(row.sourceUrl) = '') THEN null ELSE trim(row.sourceUrl) END
  }
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'nodes/Agreement.csv' AS row
WITH row WHERE NOT (row.id IS NULL OR trim(row.id) = '')
CALL (row) {
  MERGE (n:Agreement {id: trim(row.id)})
  SET n += {
    clauseNumber: CASE WHEN (row.clauseNumber IS NULL OR trim(row.clauseNumber) = '') THEN null ELSE trim(row.clauseNumber) END,
    clauseNumberNorm: CASE WHEN (row.clauseNumber IS NULL OR trim(row.clauseNumber) = '') THEN null ELSE reduce(s = '', c IN split(toUpper(row.clauseNumber), '') | s + CASE WHEN c =~ '[A-Z0-9]' THEN c ELSE '' END) END,
    signedDate: CASE WHEN (row.signedDate IS NULL OR trim(row.signedDate) = '') THEN null ELSE datetime(trim(row.signedDate)) END,
    clauseDate: CASE WHEN (row.clauseDate IS NULL OR trim(row.clauseDate) = '') THEN null ELSE datetime(trim(row.clauseDate)) END,
    witnessNames: CASE WHEN (row.witnessNames IS NULL OR trim(row.witnessNames) = '') THEN null ELSE [x IN split(trim(row.witnessNames), '|') WHERE trim(x) <> '' | trim(x)] END,
    summary: CASE WHEN (row.summary IS NULL OR trim(row.summary) = '') THEN null ELSE trim(row.summary) END,
    summaryEmbedding: CASE WHEN (row.summaryEmbedding IS NULL OR trim(row.summaryEmbedding) = '') THEN null ELSE [x IN split(trim(row.summaryEmbedding), '|') | toFloat(x)] END,
    sourceUrl: CASE WHEN (row.sourceUrl IS NULL OR trim(row.sourceUrl) = '') THEN null ELSE trim(row.sourceUrl) END
  }
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'nodes/Proposal.csv' AS row
WITH row WHERE NOT (row.id IS NULL OR trim(row.id) = '')
CALL (row) {
  MERGE (n:Proposal {id: trim(row.id)})
  SET n += {
    referenceNumber: CASE WHEN (row.referenceNumber IS NULL OR trim(row.referenceNumber) = '') THEN null ELSE trim(row.referenceNumber) END,
    referenceNumberNorm: CASE WHEN (row.referenceNumber IS NULL OR trim(row.referenceNumber) = '') THEN null ELSE reduce(s = '', c IN split(toUpper(row.referenceNumber), '') | s + CASE WHEN c =~ '[A-Z0-9]' THEN c ELSE '' END) END,
    title: CASE WHEN (row.title IS NULL OR trim(row.title) = '') THEN null ELSE trim(row.title) END,
    status: CASE WHEN (row.status IS NULL OR trim(row.status) = '') THEN null ELSE trim(row.status) END,
    submittedDate: CASE WHEN (row.submittedDate IS NULL OR trim(row.submittedDate) = '') THEN null ELSE datetime(trim(row.submittedDate)) END,
    validUntil: CASE WHEN (row.validUntil IS NULL OR trim(row.validUntil) = '') THEN null ELSE datetime(trim(row.validUntil)) END,
    proposedAmount: CASE WHEN (row.proposedAmount IS NULL OR trim(row.proposedAmount) = '') THEN null ELSE toFloat(trim(row.proposedAmount)) END,
    currency: CASE WHEN (row.currency IS NULL OR trim(row.currency) = '') THEN null ELSE trim(row.currency) END,
    includesVAT: CASE WHEN (row.includesVAT IS NULL OR trim(row.includesVAT) = '') THEN null ELSE toBoolean(trim(row.includesVAT)) END,
    summary: CASE WHEN (row.summary IS NULL OR trim(row.summary) = '') THEN null ELSE trim(row.summary) END,
    summaryEmbedding: CASE WHEN (row.summaryEmbedding IS NULL OR trim(row.summaryEmbedding) = '') THEN null ELSE [x IN split(trim(row.summaryEmbedding), '|') | toFloat(x)] END,
    sourceUrl: CASE WHEN (row.sourceUrl IS NULL OR trim(row.sourceUrl) = '') THEN null ELSE trim(row.sourceUrl) END
  }
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'nodes/Drawing.csv' AS row
WITH row WHERE NOT (row.id IS NULL OR trim(row.id) = '')
CALL (row) {
  MERGE (n:Drawing {id: trim(row.id)})
  SET n += {
    referenceNumber: CASE WHEN (row.referenceNumber IS NULL OR trim(row.referenceNumber) = '') THEN null ELSE trim(row.referenceNumber) END,
    referenceNumberNorm: CASE WHEN (row.referenceNumber IS NULL OR trim(row.referenceNumber) = '') THEN null ELSE reduce(s = '', c IN split(toUpper(row.referenceNumber), '') | s + CASE WHEN c =~ '[A-Z0-9]' THEN c ELSE '' END) END,
    title: CASE WHEN (row.title IS NULL OR trim(row.title) = '') THEN null ELSE trim(row.title) END,
    discipline: CASE WHEN (row.discipline IS NULL OR trim(row.discipline) = '') THEN null ELSE trim(row.discipline) END,
    revision: CASE WHEN (row.revision IS NULL OR trim(row.revision) = '') THEN null ELSE trim(row.revision) END,
    issueDate: CASE WHEN (row.issueDate IS NULL OR trim(row.issueDate) = '') THEN null ELSE datetime(trim(row.issueDate)) END,
    designerName: CASE WHEN (row.designerName IS NULL OR trim(row.designerName) = '') THEN null ELSE trim(row.designerName) END,
    sourceUrl: CASE WHEN (row.sourceUrl IS NULL OR trim(row.sourceUrl) = '') THEN null ELSE trim(row.sourceUrl) END
  }
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'nodes/FinancialRecord.csv' AS row
WITH row WHERE NOT (row.id IS NULL OR trim(row.id) = '')
CALL (row) {
  MERGE (n:FinancialRecord {id: trim(row.id)})
  SET n += {
    recordType: CASE WHEN (row.recordType IS NULL OR trim(row.recordType) = '') THEN null ELSE trim(row.recordType) END,
    referenceNumber: CASE WHEN (row.referenceNumber IS NULL OR trim(row.referenceNumber) = '') THEN null ELSE trim(row.referenceNumber) END,
    referenceNumberNorm: CASE WHEN (row.referenceNumber IS NULL OR trim(row.referenceNumber) = '') THEN null ELSE reduce(s = '', c IN split(toUpper(row.referenceNumber), '') | s + CASE WHEN c =~ '[A-Z0-9]' THEN c ELSE '' END) END,
    description: CASE WHEN (row.description IS NULL OR trim(row.description) = '') THEN null ELSE trim(row.description) END,
    category: CASE WHEN (row.category IS NULL OR trim(row.category) = '') THEN null ELSE trim(row.category) END,
    amount: CASE WHEN (row.amount IS NULL OR trim(row.amount) = '') THEN null ELSE toFloat(trim(row.amount)) END,
    currency: CASE WHEN (row.currency IS NULL OR trim(row.currency) = '') THEN null ELSE trim(row.currency) END,
    taxAmount: CASE WHEN (row.taxAmount IS NULL OR trim(row.taxAmount) = '') THEN null ELSE toFloat(trim(row.taxAmount)) END,
    includesVAT: CASE WHEN (row.includesVAT IS NULL OR trim(row.includesVAT) = '') THEN null ELSE toBoolean(trim(row.includesVAT)) END,
    status: CASE WHEN (row.status IS NULL OR trim(row.status) = '') THEN null ELSE trim(row.status) END,
    effectiveDate: CASE WHEN (row.effectiveDate IS NULL OR trim(row.effectiveDate) = '') THEN null ELSE datetime(trim(row.effectiveDate)) END,
    dueDate: CASE WHEN (row.dueDate IS NULL OR trim(row.dueDate) = '') THEN null ELSE datetime(trim(row.dueDate)) END,
    periodStart: CASE WHEN (row.periodStart IS NULL OR trim(row.periodStart) = '') THEN null ELSE datetime(trim(row.periodStart)) END,
    periodEnd: CASE WHEN (row.periodEnd IS NULL OR trim(row.periodEnd) = '') THEN null ELSE datetime(trim(row.periodEnd)) END,
    paymentMethod: CASE WHEN (row.paymentMethod IS NULL OR trim(row.paymentMethod) = '') THEN null ELSE trim(row.paymentMethod) END,
    transactionReference: CASE WHEN (row.transactionReference IS NULL OR trim(row.transactionReference) = '') THEN null ELSE trim(row.transactionReference) END,
    interimNumber: CASE WHEN (row.interimNumber IS NULL OR trim(row.interimNumber) = '') THEN null ELSE toInteger(trim(row.interimNumber)) END,
    paymentTerms: CASE WHEN (row.paymentTerms IS NULL OR trim(row.paymentTerms) = '') THEN null ELSE trim(row.paymentTerms) END,
    grossAmount: CASE WHEN (row.grossAmount IS NULL OR trim(row.grossAmount) = '') THEN null ELSE toFloat(trim(row.grossAmount)) END,
    netAmount: CASE WHEN (row.netAmount IS NULL OR trim(row.netAmount) = '') THEN null ELSE toFloat(trim(row.netAmount)) END,
    deductions: CASE WHEN (row.deductions IS NULL OR trim(row.deductions) = '') THEN null ELSE toFloat(trim(row.deductions)) END,
    costType: CASE WHEN (row.costType IS NULL OR trim(row.costType) = '') THEN null ELSE trim(row.costType) END,
    costCenter: CASE WHEN (row.costCenter IS NULL OR trim(row.costCenter) = '') THEN null ELSE trim(row.costCenter) END,
    fiscalYear: CASE WHEN (row.fiscalYear IS NULL OR trim(row.fiscalYear) = '') THEN null ELSE toInteger(trim(row.fiscalYear)) END,
    revisedAmount: CASE WHEN (row.revisedAmount IS NULL OR trim(row.revisedAmount) = '') THEN null ELSE toFloat(trim(row.revisedAmount)) END,
    adjustmentReason: CASE WHEN (row.adjustmentReason IS NULL OR trim(row.adjustmentReason) = '') THEN null ELSE trim(row.adjustmentReason) END,
    statementType: CASE WHEN (row.statementType IS NULL OR trim(row.statementType) = '') THEN null ELSE trim(row.statementType) END,
    summary: CASE WHEN (row.summary IS NULL OR trim(row.summary) = '') THEN null ELSE trim(row.summary) END,
    summaryEmbedding: CASE WHEN (row.summaryEmbedding IS NULL OR trim(row.summaryEmbedding) = '') THEN null ELSE [x IN split(trim(row.summaryEmbedding), '|') | toFloat(x)] END,
    sourceUrl: CASE WHEN (row.sourceUrl IS NULL OR trim(row.sourceUrl) = '') THEN null ELSE trim(row.sourceUrl) END
  }
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'nodes/BOQ.csv' AS row
WITH row WHERE NOT (row.id IS NULL OR trim(row.id) = '')
CALL (row) {
  MERGE (n:BOQ {id: trim(row.id)})
  SET n += {
    totalAmount: CASE WHEN (row.totalAmount IS NULL OR trim(row.totalAmount) = '') THEN null ELSE toFloat(trim(row.totalAmount)) END,
    currency: CASE WHEN (row.currency IS NULL OR trim(row.currency) = '') THEN null ELSE trim(row.currency) END,
    includesVAT: CASE WHEN (row.includesVAT IS NULL OR trim(row.includesVAT) = '') THEN null ELSE toBoolean(trim(row.includesVAT)) END,
    preparedDate: CASE WHEN (row.preparedDate IS NULL OR trim(row.preparedDate) = '') THEN null ELSE datetime(trim(row.preparedDate)) END,
    sourceUrl: CASE WHEN (row.sourceUrl IS NULL OR trim(row.sourceUrl) = '') THEN null ELSE trim(row.sourceUrl) END
  }
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'nodes/Schedule.csv' AS row
WITH row WHERE NOT (row.id IS NULL OR trim(row.id) = '')
CALL (row) {
  MERGE (n:Schedule {id: trim(row.id)})
  SET n += {
    dataDate: CASE WHEN (row.dataDate IS NULL OR trim(row.dataDate) = '') THEN null ELSE datetime(trim(row.dataDate)) END,
    plannedStartDate: CASE WHEN (row.plannedStartDate IS NULL OR trim(row.plannedStartDate) = '') THEN null ELSE datetime(trim(row.plannedStartDate)) END,
    plannedFinishDate: CASE WHEN (row.plannedFinishDate IS NULL OR trim(row.plannedFinishDate) = '') THEN null ELSE datetime(trim(row.plannedFinishDate)) END,
    revision: CASE WHEN (row.revision IS NULL OR trim(row.revision) = '') THEN null ELSE trim(row.revision) END,
    sourceUrl: CASE WHEN (row.sourceUrl IS NULL OR trim(row.sourceUrl) = '') THEN null ELSE trim(row.sourceUrl) END
  }
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'nodes/Report.csv' AS row
WITH row WHERE NOT (row.id IS NULL OR trim(row.id) = '')
CALL (row) {
  MERGE (n:Report {id: trim(row.id)})
  SET n += {
    reportType: CASE WHEN (row.reportType IS NULL OR trim(row.reportType) = '') THEN null ELSE trim(row.reportType) END,
    referenceNumber: CASE WHEN (row.referenceNumber IS NULL OR trim(row.referenceNumber) = '') THEN null ELSE trim(row.referenceNumber) END,
    referenceNumberNorm: CASE WHEN (row.referenceNumber IS NULL OR trim(row.referenceNumber) = '') THEN null ELSE reduce(s = '', c IN split(toUpper(row.referenceNumber), '') | s + CASE WHEN c =~ '[A-Z0-9]' THEN c ELSE '' END) END,
    title: CASE WHEN (row.title IS NULL OR trim(row.title) = '') THEN null ELSE trim(row.title) END,
    reportDate: CASE WHEN (row.reportDate IS NULL OR trim(row.reportDate) = '') THEN null ELSE datetime(trim(row.reportDate)) END,
    periodStart: CASE WHEN (row.periodStart IS NULL OR trim(row.periodStart) = '') THEN null ELSE datetime(trim(row.periodStart)) END,
    periodEnd: CASE WHEN (row.periodEnd IS NULL OR trim(row.periodEnd) = '') THEN null ELSE datetime(trim(row.periodEnd)) END,
    revision: CASE WHEN (row.revision IS NULL OR trim(row.revision) = '') THEN null ELSE trim(row.revision) END,
    status: CASE WHEN (row.status IS NULL OR trim(row.status) = '') THEN null ELSE trim(row.status) END,
    plannedTotal: CASE WHEN (row.plannedTotal IS NULL OR trim(row.plannedTotal) = '') THEN null ELSE toFloat(trim(row.plannedTotal)) END,
    executedTotal: CASE WHEN (row.executedTotal IS NULL OR trim(row.executedTotal) = '') THEN null ELSE toFloat(trim(row.executedTotal)) END,
    unit: CASE WHEN (row.unit IS NULL OR trim(row.unit) = '') THEN null ELSE trim(row.unit) END,
    summary: CASE WHEN (row.summary IS NULL OR trim(row.summary) = '') THEN null ELSE trim(row.summary) END,
    summaryEmbedding: CASE WHEN (row.summaryEmbedding IS NULL OR trim(row.summaryEmbedding) = '') THEN null ELSE [x IN split(trim(row.summaryEmbedding), '|') | toFloat(x)] END,
    sourceUrl: CASE WHEN (row.sourceUrl IS NULL OR trim(row.sourceUrl) = '') THEN null ELSE trim(row.sourceUrl) END
  }
} IN TRANSACTIONS OF 1000 ROWS;

// ---------------------------------------------------------------- relationships
LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/FOR_PROJECT__BOQ.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:BOQ {id: trim(row.startId)})
  MATCH (e:Project {id: trim(row.endId)})
  MERGE (s)-[r:FOR_PROJECT]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/FOR_PROJECT__Letter.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:Letter {id: trim(row.startId)})
  MATCH (e:Project {id: trim(row.endId)})
  MERGE (s)-[r:FOR_PROJECT]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/FOR_PROJECT__Drawing.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:Drawing {id: trim(row.startId)})
  MATCH (e:Project {id: trim(row.endId)})
  MERGE (s)-[r:FOR_PROJECT]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/FOR_PROJECT__Agreement.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:Agreement {id: trim(row.startId)})
  MATCH (e:Project {id: trim(row.endId)})
  MERGE (s)-[r:FOR_PROJECT]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/FOR_PROJECT__Schedule.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:Schedule {id: trim(row.startId)})
  MATCH (e:Project {id: trim(row.endId)})
  MERGE (s)-[r:FOR_PROJECT]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/FOR_PROJECT__Report.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:Report {id: trim(row.startId)})
  MATCH (e:Project {id: trim(row.endId)})
  MERGE (s)-[r:FOR_PROJECT]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/FOR_PROJECT__EOTClaim.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:EOTClaim {id: trim(row.startId)})
  MATCH (e:Project {id: trim(row.endId)})
  MERGE (s)-[r:FOR_PROJECT]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/FOR_PROJECT__Proposal.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:Proposal {id: trim(row.startId)})
  MATCH (e:Project {id: trim(row.endId)})
  MERGE (s)-[r:FOR_PROJECT]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/FOR_PROJECT__FinancialRecord.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:FinancialRecord {id: trim(row.startId)})
  MATCH (e:Project {id: trim(row.endId)})
  MERGE (s)-[r:FOR_PROJECT]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/CLIENT_OF.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:Organization {id: trim(row.startId)})
  MATCH (e:Project {id: trim(row.endId)})
  MERGE (s)-[r:CLIENT_OF]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/CONTRACTOR_OF.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:Organization {id: trim(row.startId)})
  MATCH (e:Project {id: trim(row.endId)})
  MERGE (s)-[r:CONTRACTOR_OF]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/CONSULTANT_OF.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:Organization {id: trim(row.startId)})
  MATCH (e:Project {id: trim(row.endId)})
  MERGE (s)-[r:CONSULTANT_OF]->(e)
  SET r += {
    role: CASE WHEN (row.role IS NULL OR trim(row.role) = '') THEN null ELSE trim(row.role) END
  }
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/SENT_BY.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:Letter {id: trim(row.startId)})
  MATCH (e:Organization {id: trim(row.endId)})
  MERGE (s)-[r:SENT_BY]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/ADDRESSED_TO.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:Letter {id: trim(row.startId)})
  MATCH (e:Organization {id: trim(row.endId)})
  MERGE (s)-[r:ADDRESSED_TO]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/SUBMITTED_BY__EOTClaim.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:EOTClaim {id: trim(row.startId)})
  MATCH (e:Organization {id: trim(row.endId)})
  MERGE (s)-[r:SUBMITTED_BY]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/SUBMITTED_BY__Proposal.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:Proposal {id: trim(row.startId)})
  MATCH (e:Organization {id: trim(row.endId)})
  MERGE (s)-[r:SUBMITTED_BY]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/DESIGNED_BY.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:Drawing {id: trim(row.startId)})
  MATCH (e:Organization {id: trim(row.endId)})
  MERGE (s)-[r:DESIGNED_BY]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/SIGNED_BY.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:Agreement {id: trim(row.startId)})
  MATCH (e:Organization {id: trim(row.endId)})
  MERGE (s)-[r:SIGNED_BY]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/CITES.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:EOTClaim {id: trim(row.startId)})
  MATCH (e:Agreement {id: trim(row.endId)})
  MERGE (s)-[r:CITES]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/PREPARED_BY.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:Report {id: trim(row.startId)})
  MATCH (e:Organization {id: trim(row.endId)})
  MERGE (s)-[r:PREPARED_BY]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/INVOLVES.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:FinancialRecord {id: trim(row.startId)})
  MATCH (e:Organization {id: trim(row.endId)})
  MERGE (s)-[r:INVOLVES]->(e)
  SET r += {
    role: CASE WHEN (row.role IS NULL OR trim(row.role) = '') THEN null ELSE trim(row.role) END
  }
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/REFERENCED_IN.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:FinancialRecord {id: trim(row.startId)})
  MATCH (e:Letter {id: trim(row.endId)})
  MERGE (s)-[r:REFERENCED_IN]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

LOAD CSV WITH HEADERS FROM $baseUrl + 'relationships/GOVERNED_BY.csv' AS row
WITH row WHERE NOT (row.startId IS NULL OR trim(row.startId) = '') AND NOT (row.endId IS NULL OR trim(row.endId) = '')
CALL (row) {
  MATCH (s:FinancialRecord {id: trim(row.startId)})
  MATCH (e:Agreement {id: trim(row.endId)})
  MERGE (s)-[r:GOVERNED_BY]->(e)
} IN TRANSACTIONS OF 1000 ROWS;

// ---------------------------------------------------------------- optional: embed in the database
// Use this instead of pre-computed summaryEmbedding values. Needs the GenAI plugin
// (database plugin configuration: NEO4J_PLUGINS='["genai"]') and an OpenAI key:
//   :param openaiKey => 'sk-...'
// Newer plugin versions also offer ai.text.embed(); genai.vector.encode still works.
// MATCH (n:Project) WHERE n.summary IS NOT NULL AND n.summaryEmbedding IS NULL
// CALL (n) { SET n.summaryEmbedding = genai.vector.encode(n.summary, 'OpenAI', {token: $openaiKey, model: 'text-embedding-3-small', dimensions: 1536}) } IN TRANSACTIONS OF 100 ROWS;
// MATCH (n:Letter) WHERE n.summary IS NOT NULL AND n.summaryEmbedding IS NULL
// CALL (n) { SET n.summaryEmbedding = genai.vector.encode(n.summary, 'OpenAI', {token: $openaiKey, model: 'text-embedding-3-small', dimensions: 1536}) } IN TRANSACTIONS OF 100 ROWS;
// MATCH (n:EOTClaim) WHERE n.summary IS NOT NULL AND n.summaryEmbedding IS NULL
// CALL (n) { SET n.summaryEmbedding = genai.vector.encode(n.summary, 'OpenAI', {token: $openaiKey, model: 'text-embedding-3-small', dimensions: 1536}) } IN TRANSACTIONS OF 100 ROWS;
// MATCH (n:Agreement) WHERE n.summary IS NOT NULL AND n.summaryEmbedding IS NULL
// CALL (n) { SET n.summaryEmbedding = genai.vector.encode(n.summary, 'OpenAI', {token: $openaiKey, model: 'text-embedding-3-small', dimensions: 1536}) } IN TRANSACTIONS OF 100 ROWS;
// MATCH (n:Proposal) WHERE n.summary IS NOT NULL AND n.summaryEmbedding IS NULL
// CALL (n) { SET n.summaryEmbedding = genai.vector.encode(n.summary, 'OpenAI', {token: $openaiKey, model: 'text-embedding-3-small', dimensions: 1536}) } IN TRANSACTIONS OF 100 ROWS;
// MATCH (n:FinancialRecord) WHERE n.summary IS NOT NULL AND n.summaryEmbedding IS NULL
// CALL (n) { SET n.summaryEmbedding = genai.vector.encode(n.summary, 'OpenAI', {token: $openaiKey, model: 'text-embedding-3-small', dimensions: 1536}) } IN TRANSACTIONS OF 100 ROWS;
// MATCH (n:Report) WHERE n.summary IS NOT NULL AND n.summaryEmbedding IS NULL
// CALL (n) { SET n.summaryEmbedding = genai.vector.encode(n.summary, 'OpenAI', {token: $openaiKey, model: 'text-embedding-3-small', dimensions: 1536}) } IN TRANSACTIONS OF 100 ROWS;
