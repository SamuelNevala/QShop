# Play creation declarations

Reviewed 12–16 November 2026. No app entry or declaration has been submitted;
technical checks do not accept agreements for the owner.

| Declaration | Prepared position | Remaining action |
| --- | --- | --- |
| Developer Programme Policies | Privacy/minimized permissions and offline licence notices are implemented | Save live policy URL/form answers; publish accepted exact sources; finish regional/listing/content tasks |
| Play App Signing | Compatible with planned AAB distribution | Owner reviews/accepts terms, creates upload key and enrolls store signing |
| US export laws | Code-5 review supports ordinary shopping app / likely EAR99 if subject to EAR | Finish actual country/regional/end-use checks; owner reviews declaration |

## What changed since the initial code-3 review

- Missing policy/access was fixed: local/offline reader and accepted public
  [privacy page](https://samuelnevala.github.io/QShop/privacy-policy.html), exact
  anonymous HTML verified 12 November. Console field remains unsaved.
- Unneeded Internet/network-state/storage permissions were removed in code 4;
  code 5 retains only AndroidX's internal signature receiver permission. Backup
  remains enabled. Explicit development QML debugging is separate from Release.
- Code 5 added complete App/Maven/NDK notices and exact source-set preparation.
  Local candidate archives are not published source delivery.
- No app account, network client, ad/analytics SDK, camera/microphone access or
  billing integration was found. Keyboard dictation/platform backup are separate
  services, not a promise that nothing leaves the device.

## Next owner decisions

Finland, all eligible markets, adult household audience and paid download are
selected; price remains undecided. Adult targeting is not an IARC rating or an
age-gate instruction. Accurate trader declaration, merchant/payment tasks and
regional applicability remain under the [checklist](../store/google-play/REGIONAL_CHECKLIST.md).
Public contacts are supplied in the [terms draft](../store/google-play/TERMS_DRAFT.md);
wording acceptance and publication remain open.

Read the [privacy](REL-001-privacy.md), [licensing/source](REL-001-licensing.md),
[export](REL-001-export.md) and [terms](REL-001-terms.md) reviews, then review the
actual Console summary. App creation, source publication, signing and store
rollout are distinct actions. No production key/upload is claimed.

References: [User Data](https://support.google.com/googleplay/android-developer/answer/10144311),
[permissions](https://support.google.com/googleplay/android-developer/answer/16558241),
[Play signing](https://support.google.com/googleplay/android-developer/answer/9842756),
[Google export](https://support.google.com/googleplay/android-developer/answer/113770),
[Qt export](https://doc.qt.io/qt-6/exportcontrols.html),
[GPL paid distribution](https://www.gnu.org/licenses/gpl-faq.en.html#DoesTheGPLAllowMoney).
Original code-3 findings: `git show 73ada02:reviews/REL-001-declarations.md`.
