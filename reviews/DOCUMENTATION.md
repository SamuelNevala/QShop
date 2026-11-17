# Documentation and privacy review

Reviewed 17 November 2026. Human build instructions now start with
[Qt Creator](../BUILDING.md); automation constraints stay in [AGENTS.md](../AGENTS.md).
Long logs are condensed into decisions, coverage and results. Original detail
remains in Git at 73ada02 and structured tickets. No ticket is closed by this cleanup.

## Current files

- Replaced artwork-generation workstation paths with output identifiers and
  repository-relative references; removed a local startup-data path from a ticket.
- Generalized the physical display inventory without changing rendering tests
  or the application's existing density correction.
- Public contact details were explicitly supplied for the
  [canonical terms](../store/google-play/TERMS.md). They are intentional
  disclosures, not copied account-verification records. Terms were unpublished at this review; the later publication
  is tracked in [REL-001 terms](REL-001-terms.md).
- Pattern checks found no remaining user-home paths, private-key material,
  supported token formats or credential-bearing URLs in current source files.
  UTF-8, UTF-16 and decoded JSON strings were checked. Generic SDK paths, emulator
  identifiers and standard test/debug credentials are not private machine details.
- Metadata inspection of 36 current PNG/JPEG assets found no personal-path matches.

## History still contains old details

The reachable-history scan covered **148 commits / 1,411 blobs**. Earlier artwork
and validation records contain local paths. Commit metadata also retains two
former work-email identities. No private-key or supported token pattern matched.
This cleanup does **not** remove historical disclosures or rewrite branches/tags.
History cleanup would require a separately agreed rewrite and coordination with
existing clones; old public copies would not thereby disappear.

## Validation and limits

Local Markdown links/headings, documented script flags, JSON, terms-preview text
and unchanged Android source inputs were checked. Actual licence/notice text,
accepted privacy policy, app code and image bytes are unchanged. No runtime test
result is claimed from documentation checks.

This was pattern/metadata review, not proof that arbitrary encoded secrets or
all visual content are absent. Ignored build/log directories are not public source;
older local source archives predate cleanup. Regenerate and inspect the accepted
source set before publication. Nothing was pushed or published by this work.
