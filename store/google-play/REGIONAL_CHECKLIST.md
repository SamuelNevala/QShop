# Regional publication checklist

Prepared **15 November 2026** for REL-001. Owner choices: **Finland**, personal
developer account, one-time paid download, **all eligible Google Play markets**,
and **adults 18+ doing household shopping**. EUR 2.99 is still a proposal.
This checklist records preparation and outstanding actions, not submitted forms
or country-by-country clearance. No live account settings were inspected.

## App entry and content

| Item | Prepared position | Remaining action |
| --- | --- | --- |
| Country/account | Finland/personal; identity verification owner-confirmed | Merchant/regional tasks are separate |
| Payment model | Paid download; public GPL source | Owner selects price; verify payout setup |
| Audience | Adults 18+; owner-confirmed 15 November | Enter intended age group in Console |
| Content rating | Shopping utility with bundled illustrated artwork | Complete IARC questionnaire; no rating has been assigned |
| Access and ads | No app login or advertising feature found | Proposed answers: unrestricted reviewer access without credentials; no ads. Check actual form wording |
| Privacy/Data safety | Published/offline policy and [draft answers](data-safety.md) | Review final artifact and save actual Console answers/URL |
| Initial markets | All eligible paid-app markets | Retain final country roster and completed regional checks |

[Target audience](https://support.google.com/googleplay/android-developer/answer/9867159?hl=en)
describes intended design/marketing; [content rating](https://support.google.com/googleplay/android-developer/answer/9859655?hl=en)
comes from a separate questionnaire. Adult targeting does not mean selecting an
18+ content rating. The owner has not requested an in-app age gate or selected
a Console option to exclude under-18 users. Local age-related applicability still
requires review; the target-age answer alone does not settle it.

## Merchant/trader actions

Google's [trader declaration](https://support.google.com/googleplay/android-developer/answer/17594752)
requires new accounts to declare at creation and existing accounts by
**1 February 2027**. Check the actual prompt for this account, created 8 November.
A personal account can be a trader. Planned commercial paid-app sales support a
**Trader recommendation for owner review**; no declaration is made on that basis
without the owner's review of their actual activity.

Trader requirements include an app terms-of-service URL and, for a personal
account, public contact phone/address information. Separately, Google's
[account guidance](https://support.google.com/googleplay/android-developer/answer/13634081?hl=en)
requires monetizing merchant accounts to display their payments-profile address.
The approved email is `samuel.nevala@gmail.com`. The
[app terms](TERMS.md) have owner-supplied public contacts and a dated page
prepared on 18 November. Deployment verification and the Console URL remain open. Enter private verification details directly in
Console/Payments Center, not repository files. Identity verification does not
establish completion of these separate tasks.

## Regional sales checks

Map from Google's [regional requirements](https://support.google.com/googleplay/android-developer/answer/6223646?hl=en):

| Scope | Action / QShopper relevance |
| --- | --- |
| EU | Avoid unjustified geo-blocking; all-eligible-market scope supports broad availability |
| Japan | Verify merchant contact disclosures from the linked payments profile |
| Brazil | Complete applicable merchant verification; assess Digital ECA/age-signal obligations, including likely minor access |
| Korea | Listed game/location rules do not match this app; Korean-developer-only fields do not describe this Finnish publisher |
| India | Listed gaming/investment requirements do not match this shopping utility |
| Israel | Cited payout KYC is tied to Israeli billing addresses, not merely Israeli buyers |
| Vietnam | Cited online-game licensing does not match this non-game |

### Japan payments

The [29 October notice](https://support.google.com/googleplay/android-developer/answer/18100766?hl=en)
announces a **1 December 2026** authorization deadline. Check this account's
invitation/deadline. The [dedicated instructions](https://support.google.com/paymentscenter/answer/17595997)
apply to overseas developers selling into Japan. PSA authorization appoints Google
as payment collection agent; ISA disclosures are separate. A new seller can
receive the ISA task after its first Japanese sale. Missing requirements can
hold payouts globally. The owner must review the forms and provide truthful
identity/legal-history answers; none has been submitted or assumed here.

### Age-related applicability

Brazil's applicability question remains open. Review the current
[regional age protections](https://developer.android.com/distribute/age-appropriate-experiences/regional-protections)
before production. Restrictions on locally 18+-rated content differ from the
adult target-audience choice. No requirement to add an age API to every shopping
app is inferred. The [Age Signals documentation](https://developer.android.com/google/play/age-signals/overview)
describes an available integration and its terms, not this app's legal status.
No SDK, permission, collection or UI change is made. Any required implementation
remains REL-001 work with its own tests and renewed package/license/privacy review.

## Final release record

1. Resolve price, accurate trader declaration, public contact/terms information
   and account-specific payment prompts. No completion is inferred from silence.
2. Use current [paid-app availability](https://support.google.com/googleplay/answer/143779?hl=en)
   and the actual Console roster. Check regional tasks and the
   [export assessment](../../reviews/REL-001-export.md); availability alone is not
   a sanctions/payment guarantee. Retain roster, date and completion evidence.
3. Record actual IARC results, Data safety/access/ads answers and policy URL.
4. Publish/verify the [accepted source set](../../SOURCE_DISTRIBUTION.md), finish
   production signing and required Play testing, then review the submission
   summary before owner publication approval. REL-001 remains open.

Only documentation changed. Local links and JSON are checked; app/UI tests were
not rerun. Earlier artifact results establish their unchanged build's behavior,
not completion of live account or regional requirements.
