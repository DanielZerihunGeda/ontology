// =====================================================================
// Knowledge graph: run AFTER loading data with Data Importer (model.json)
// Generated from model.tsv by generate.py. Do not edit by hand.
// Adds what Data Importer cannot: search indexes and normalised reference copies.
// Safe to re-run. Not needed after import.cypher, which already does both.
// =====================================================================

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

// ---------------------------------------------------------------- normalised reference copies
MATCH (n:Letter) WHERE n.referenceNumber IS NOT NULL
SET n.referenceNumberNorm = CASE WHEN (n.referenceNumber IS NULL OR trim(n.referenceNumber) = '') THEN null ELSE reduce(s = '', c IN split(toUpper(n.referenceNumber), '') | s + CASE WHEN c =~ '[A-Z0-9]' THEN c ELSE '' END) END;
MATCH (n:Agreement) WHERE n.clauseNumber IS NOT NULL
SET n.clauseNumberNorm = CASE WHEN (n.clauseNumber IS NULL OR trim(n.clauseNumber) = '') THEN null ELSE reduce(s = '', c IN split(toUpper(n.clauseNumber), '') | s + CASE WHEN c =~ '[A-Z0-9]' THEN c ELSE '' END) END;
MATCH (n:Proposal) WHERE n.referenceNumber IS NOT NULL
SET n.referenceNumberNorm = CASE WHEN (n.referenceNumber IS NULL OR trim(n.referenceNumber) = '') THEN null ELSE reduce(s = '', c IN split(toUpper(n.referenceNumber), '') | s + CASE WHEN c =~ '[A-Z0-9]' THEN c ELSE '' END) END;
MATCH (n:Drawing) WHERE n.referenceNumber IS NOT NULL
SET n.referenceNumberNorm = CASE WHEN (n.referenceNumber IS NULL OR trim(n.referenceNumber) = '') THEN null ELSE reduce(s = '', c IN split(toUpper(n.referenceNumber), '') | s + CASE WHEN c =~ '[A-Z0-9]' THEN c ELSE '' END) END;
MATCH (n:FinancialRecord) WHERE n.referenceNumber IS NOT NULL
SET n.referenceNumberNorm = CASE WHEN (n.referenceNumber IS NULL OR trim(n.referenceNumber) = '') THEN null ELSE reduce(s = '', c IN split(toUpper(n.referenceNumber), '') | s + CASE WHEN c =~ '[A-Z0-9]' THEN c ELSE '' END) END;
MATCH (n:Report) WHERE n.referenceNumber IS NOT NULL
SET n.referenceNumberNorm = CASE WHEN (n.referenceNumber IS NULL OR trim(n.referenceNumber) = '') THEN null ELSE reduce(s = '', c IN split(toUpper(n.referenceNumber), '') | s + CASE WHEN c =~ '[A-Z0-9]' THEN c ELSE '' END) END;

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
