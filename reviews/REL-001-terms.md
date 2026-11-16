# Public app terms preparation

Prepared **16 November 2026**. The owner approved drafting the public app terms
after the licensing, export and regional reviews. This is a reviewable draft,
not owner acceptance of its wording, a legal compliance ruling or publication.

## Draft and scope

The canonical draft is [TERMS_DRAFT.md](../store/google-play/TERMS_DRAFT.md).
A local HTML preview is prepared under `out/rel001/terms/terms-draft.html`, using
the existing privacy page's simple typography. Neither a public `docs/terms.html`
page nor a landing-page link is added yet, so the next unrelated Pages push does
not accidentally activate a draft. Intended eventual URL:
`https://samuelnevala.github.io/QShop/terms.html` — **not live or verified**.

The draft describes the approved one-time paid build model without setting an
unapproved price. It preserves GPL-3.0-or-later freedoms and separate dependency
terms, points to source/build information and the accepted privacy policy, and
distinguishes the app/developer from the seller/purchase terms shown by Play.
No subscription, in-app payment, new support service or age gate is introduced.

Consumer protections are preserved alongside the GPL warranty text. The draft
does not impose a blanket no-refund rule, a purchase-price liability cap,
exclusive Finnish courts or new restrictions on copying/redistribution. It does
not claim that an adult target audience is a restriction on running GPL software.
There is no click-through acceptance mechanism or retroactive effective date.

## Publication checklist

| Item | Status / action |
| --- | --- |
| Owner wording review | Pending; review the actual draft before acceptance |
| Developer name/email | Samuel Nevala and samuel.nevala@gmail.com, already recorded publicly in the project |
| Public trader address/phone | Marked fields remain. Owner supplies intended public details; do not copy private account information into Git implicitly. Check basic-rate contract-support contact and any applicable registry disclosures |
| Trader status | Recommendation remains Trader for the planned commercial paid app; owner decides/submits the accurate declaration |
| Seller and checkout | Verify actual Play seller/purchase terms, immediate-supply consent, applicable withdrawal information and online withdrawal route/confirmation before sales. No checkout inspection is claimed |
| Mandatory updates/remedies | Draft retains applicable legal duties; no indefinite feature/compatibility promise or fixed support duration is invented |
| Source delivery | Commit/publish the accepted guide and exact release source set; the draft's master-branch guide URL is not evidence that matching sources are already delivered |
| Privacy policy | Accepted existing public/offline policy remains unchanged |
| Complaints | Includes Finnish consumer advice and ADR references without restricting other remedies; verify routing for the actual seller/consumer location |
| Effective version | Set at accepted publication; remove draft notice and contact placeholders then |
| Public page/Console | After review/completion, prepare docs/terms.html, link from docs/index.html, publish and verify public content; only then use the live URL in Console |

The phone/address and final wording gaps prevent this draft from being used as
completed trader terms now. They do not prevent reviewing the prepared text.
Existing candidate source snapshots predate these documentation changes;
regenerate the final source set after the accepted revision as already planned.

## Official references checked

- [Google trader declaration](https://support.google.com/googleplay/android-developer/answer/17594752): app terms link and personal trader contact disclosures, separate from identity verification.
- [Google Play refunds](https://support.google.com/googleplay/answer/2479637?hl=en) and [EEA/UK information](https://support.google.com/googleplay/answer/7659581): store processes vary by purchase/location; developer contact remains available.
- [GNU GPL v3](https://www.gnu.org/licenses/gpl-3.0.html), especially sections 4, 6 and 10: charging for distribution and preserving software/source rights. Root LICENSE/COPYRIGHT establish the project's chosen grant.
- [FCCA digital content guidance](https://www.kkv.fi/en/consumer-affairs/digital-content-and-services/): conformity, necessary updates and statutory remedies. A GPL disclaimer is not used to disclaim paid consumer-sale duties.
- [FCCA pre-contract information](https://www.kkv.fi/en/consumer-affairs/online-stores/obligation-to-provide-information-in-online-stores/): identity/contact, withdrawal information and ADR. Live checkout/withdrawal-function requirements need checking for the actual store arrangement; no new in-app checkout or withdrawal button is inferred.
- [Finnish consumer advice](https://www.kkv.fi/en/consumer-affairs/consumer-advisory-services/) and [Consumer Disputes Board](https://www.kuluttajariita.fi/en/): complaint assistance and dispute route, subject to eligibility.

Only documentation and a local preview are prepared. Text/link/HTML consistency
checks do not certify legal sufficiency or completion of Play's live tasks.
Application behavior is unchanged; app builds/UI tests are not rerun for this work.
