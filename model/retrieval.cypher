// =====================================================================
// Knowledge graph: retrieval patterns
// Index names follow import.cypher: <label_snake>_text, <label_snake>_summary_embedding.
//
//   Label      full-text index   vector index
//   Project    project_text      project_summary_embedding
//   Letter     letter_text       letter_summary_embedding
//   EOTClaim   eot_claim_text    eot_claim_summary_embedding
//   Agreement  agreement_text    agreement_summary_embedding
//   Proposal   proposal_text     proposal_summary_embedding
//   Report     report_text       report_summary_embedding
//   FinancialRecord financial_record_text financial_record_summary_embedding
//   Drawing    drawing_text      (none, title only)
// =====================================================================


// ---------------------------------------------------------------------
// 1. Weighted hybrid search: Lucene + semantic (cosine)
//    score = alpha * semantic + (1 - alpha) * lucene, each normalised to its own top hit.
//    Default alpha = 0.75 (model.tsv: hybridAlpha).
//    Params: $vectorIndex, $textIndex, $queryText, $queryEmbedding (1536 floats), $k, $alpha
//    Escape Lucene special characters in $queryText (+ - && || ! ( ) { } [ ] ^ " ~ * ? : \ /).
// ---------------------------------------------------------------------
CALL () {
  CALL db.index.vector.queryNodes($vectorIndex, $k, $queryEmbedding) YIELD node, score
  WITH collect({node: node, score: score}) AS hits, max(score) AS top
  UNWIND hits AS h
  RETURN h.node AS node, h.score / top AS semantic, 0.0 AS lucene
  UNION ALL
  CALL db.index.fulltext.queryNodes($textIndex, $queryText, {limit: $k}) YIELD node, score
  WITH collect({node: node, score: score}) AS hits, max(score) AS top
  UNWIND hits AS h
  RETURN h.node AS node, 0.0 AS semantic, h.score / top AS lucene
}
WITH node, max(semantic) AS semantic, max(lucene) AS lucene
WITH node, semantic, lucene, $alpha * semantic + (1 - $alpha) * lucene AS score
OPTIONAL MATCH (node)-[:FOR_PROJECT]->(p:Project)
RETURN node {.*, summaryEmbedding: null} AS record, p.name AS project,
       round(score, 4) AS score, round(semantic, 4) AS semantic, round(lucene, 4) AS lucene
ORDER BY score DESC
LIMIT $k;


// ---------------------------------------------------------------------
// 2. Fuzzy name match (Levenshtein) on name + aliases. Needs APOC.
//    Works for Organization and Project. Partial names of 4+ characters ("Abay") score 1.0
//    via CONTAINS; shorter inputs ("ERA") must match a name or alias by edit distance, so
//    "era" does not hit "Federal ...". Misspellings ("Abbay Consltants") score by similarity.
//    Params: $name, $minSimilarity (e.g. 0.75)
// ---------------------------------------------------------------------
MATCH (o:Organization)
WITH o, toLower(trim($name)) AS q
WITH o, [x IN [o.name] + coalesce(o.aliases, []) |
         CASE WHEN size(q) >= 4 AND toLower(x) CONTAINS q THEN 1.0
              ELSE apoc.text.levenshteinSimilarity(toLower(x), q) END] AS sims
WITH o, reduce(best = 0.0, s IN sims | CASE WHEN s > best THEN s ELSE best END) AS similarity
WHERE similarity >= $minSimilarity
RETURN o.id AS id, o.name AS name, o.aliases AS aliases, round(similarity, 3) AS similarity
ORDER BY similarity DESC
LIMIT 10;


// ---------------------------------------------------------------------
// 3. Exact reference lookup, tolerant of spacing/punctuation.
//    Normalise the input the same way the import does, then hit the *Norm index.
//    Params: $reference
// ---------------------------------------------------------------------
WITH reduce(s = '', c IN split(toUpper($reference), '') |
            s + CASE WHEN c =~ '[A-Z0-9]' THEN c ELSE '' END) AS ref
MATCH (l:Letter {referenceNumberNorm: ref})
OPTIONAL MATCH (l)-[:SENT_BY]->(sender:Organization)
RETURN l {.*, summaryEmbedding: null} AS letter, sender.name AS sender;


// ---------------------------------------------------------------------
// 4. Hybrid search scoped to one project (filter first, then rank).
//    Params as in 1, plus $projectId. Use a larger $k on the index calls when the
//    project is a small share of the graph, since filtering happens after the index.
// ---------------------------------------------------------------------
CALL () {
  CALL db.index.vector.queryNodes($vectorIndex, $k * 10, $queryEmbedding) YIELD node, score
  WHERE EXISTS { (node)-[:FOR_PROJECT]->(:Project {id: $projectId}) }
  WITH collect({node: node, score: score}) AS hits, max(score) AS top
  UNWIND hits AS h
  RETURN h.node AS node, h.score / top AS semantic, 0.0 AS lucene
  UNION ALL
  CALL db.index.fulltext.queryNodes($textIndex, $queryText, {limit: $k * 10}) YIELD node, score
  WHERE EXISTS { (node)-[:FOR_PROJECT]->(:Project {id: $projectId}) }
  WITH collect({node: node, score: score}) AS hits, max(score) AS top
  UNWIND hits AS h
  RETURN h.node AS node, 0.0 AS semantic, h.score / top AS lucene
}
WITH node, max(semantic) AS semantic, max(lucene) AS lucene
RETURN node {.*, summaryEmbedding: null} AS record,
       round($alpha * semantic + (1 - $alpha) * lucene, 4) AS score
ORDER BY score DESC
LIMIT $k;
