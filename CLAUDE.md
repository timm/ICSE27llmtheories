# Project rules

## Citations

When suggesting a citation, append the BibTeX entry to `main.bib` with a
verification-link comment immediately above it. Format:

```
% ? https://link.that.confirms.entry
@article{key2024foo,
  ...
}
```

- Marker `? ` = unverified (newly added, user has not checked link yet).
- User flips `? ` to `! ` after manually visiting the link and confirming
  the citation matches.
- Never add a citation without a confirmation link.
- Never invent DOIs, URLs, or page numbers — if no real link, do not add.

## Anti-hallucination rules for citations

1. **Verify before write.** Use WebFetch/WebSearch to confirm title, authors,
   year, venue exist together. Do not write a BibTeX entry from memory.
2. **Canonical sources only.** Prefer DOI link, arXiv abs URL, ACM DL,
   IEEE Xplore, Springer, or publisher page. Avoid blog posts, ResearchGate,
   PDFs of unknown provenance.
3. **If unsure, do not cite.** Say "I cannot verify a citation for this
   claim" rather than emit a plausible-looking fake.
4. **Quote, do not paraphrase.** When summarising what a cited paper says,
   read its abstract via WebFetch first. No claims about content from
   memory of the title alone.
5. **No key reuse.** Each BibTeX key must correspond to one verified paper.
   Do not duplicate a key with altered fields.
6. **Mark uncertainty inline.** If a field is guessed (e.g. exact page
   numbers, month), leave it blank rather than fabricate.
7. **Mass adds banned.** Never add more than one unverified citation in a
   single edit — user must be able to check each `? ` link in one pass.
8. **No "et al." inventions.** Author list must come from the verified
   source, not extrapolated from a first-author name.
9. **Report failures.** If a search returns nothing, tell the user and stop.
   Do not substitute a "similar" paper.
