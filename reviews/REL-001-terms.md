# App terms publication

Version **18 November 2026**. The page is prepared from the reviewed draft. The wording
is unchanged except for its dated version line; public contacts were explicitly
supplied on 17 November. The owner explicitly approved publishing the terms, including those contacts,
to SamuelNevala/QShop and its GitHub Pages URL on 18 November, after the initial
automatic approval review blocked the push.

Canonical [TERMS.md](../store/google-play/TERMS.md) generates
[docs/terms.html](../docs/terms.html). The landing page links to it.
Published at [the terms URL](https://samuelnevala.github.io/QShop/terms.html) on 18 November 2026.
Unauthenticated HTTPS returned 200 and exactly matched the approved HTML; the
landing link and unchanged privacy page also matched. Evidence: out/rel001/terms/live-check.json.
No Console field, agreement, signing key or app release is completed by this work.

## Maintenance and checks

Run `python tools/export-terms.py`, then `python tools/export-terms.py --check`.
The exporter uses only Python's standard library; ordinary app builds need neither
Python nor this page. Privacy HTML and bundled policy remain unchanged.

Local HTML text/links match all 19 canonical blocks and nine links. Phone-width
(390 px) and desktop (1280 px) browser review found no horizontal overflow;
the final paragraph is reachable. Styling matches the privacy page, without
scripts, remote assets or trackers. Details: out/rel001/terms/publication-check.json.
Trader, regional refunds and Finnish digital-content guidance were rechecked
18 November; the text is not an overall compliance certificate.

## Remaining release work

- Confirm accurate trader/payment-profile/registry facts and basic-rate support.
- Verify actual Play seller, checkout terms, immediate-supply consent and
  withdrawal route/confirmation before sales.
- Publish matching sources from the accepted revision. Existing local archives
  predate cleanup; none is presented as published Corresponding Source.
- Enter the verified terms URL in Console. REL-001 stays open.

## References checked 16 November 2026

- [Google trader declaration](https://support.google.com/googleplay/android-developer/answer/17594752): terms URL and contact disclosures.
- [Play refunds](https://support.google.com/googleplay/answer/2479637?hl=en), [EEA/UK purchases](https://support.google.com/googleplay/answer/7659581): purchase-specific processes.
- [GPL v3](https://www.gnu.org/licenses/gpl-3.0.html): paid distribution and retained source/software rights.
- [FCCA digital content](https://www.kkv.fi/en/consumer-affairs/digital-content-and-services/) and [pre-contract information](https://www.kkv.fi/en/consumer-affairs/online-stores/obligation-to-provide-information-in-online-stores/): conformity, updates, remedies and disclosures.
- [Finnish consumer advice](https://www.kkv.fi/en/consumer-affairs/consumer-advisory-services/) and [Consumer Disputes Board](https://www.kuluttajariita.fi/en/): complaints and eligible ADR.
