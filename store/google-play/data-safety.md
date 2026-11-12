# QShopper Data safety draft

Prepared for the permission-minimized 0.1.0/code-4 Android candidate on
12 November 2026. Review the exact accepted artifact and the live Console form
before submission. Nothing in this file has been submitted to Google.

## Proposed answers

| Question or topic | Proposed answer | Reason |
| --- | --- | --- |
| Does the app collect or share the listed user-data types? | No, for this candidate's app-side behavior | Shopping data stays in private app storage; no app network permission, analytics, advertising or custom crash SDK is included |
| Data collected | No app-side data types selected | No shopping text, device identifiers, location, contacts, audio, payment data or diagnostics are transmitted by QShopper or a bundled SDK |
| Data shared | No app-side data types selected | No developer-operated server, sharing integration or advertising destination |
| Account creation | No QShopper account | A Play/Android/keyboard account belongs to that service, not QShopper |
| Account deletion URL | Not applicable to QShopper account creation | Users can remove local data in the app or Android storage settings; support/privacy enquiries use the published email |
| Encryption in transit | No app-side collected data; follow the form's applicable questions | Do not invent an app TLS connection or answer as though unencrypted personal data is sent |
| Privacy-policy URL | [Published policy](https://samuelnevala.github.io/QShop/privacy-policy.html) | Anonymous HTTPS fetch returned 200 and exactly matched the accepted `docs/privacy-policy.html` on 12 November 2026; saving the Console field is pending |

Google defines collection as transmitting data off the device, including through
bundled libraries. These answers apply to the official permission-minimized
release. They are not answers for a remote-debugging build or a future version
with cloud, analytics or payment SDKs. If other versions are distributed through
Play, the form must cover their combined behavior.

## Services described separately in the policy

- Android backup/device transfer is enabled and controlled by the user's system
  and provider. The developer has no access to the shopping-list backups.
- Keyboard dictation is the selected IME's feature; QShopper receives inserted
  text and does not request microphone access. The keyboard may use its own
  network service under its settings.
- Google Play handles the paid download. Seller tools may expose order records
  to the developer; the app does not collect card details or use a billing SDK.
- Google/Android platform reports differ from a crash/analytics SDK embedded in
  the app. Reassess if one is later added or if optional Play protection changes
  the actual delivered artifact's behavior.
- Voluntary support emails are outside the app's data path and are addressed in
  the policy, including their use and retention. This is not a promise that
  the developer receives no personal information through any channel.
- Visiting the public policy uses GitHub hosting; reading the bundled policy
  does not open a network connection.

Do not transfer these distinctions blindly to a different live question. Check
the final form wording against the audit and actual provider behavior.

## Evidence and references

See [the privacy audit](../../reviews/REL-001-privacy.md), the canonical bundled
[policy](../../app/privacy-policy.txt), and the matching
[public HTML](../../docs/privacy-policy.html). The support/privacy contact chosen
by the owner is **samuel.nevala@gmail.com**.

[Google's Data safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469)
defines the form and collection/sharing scope. The
[User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311)
also requires the policy itself and consistent disclosures. Android's
[backup documentation](https://developer.android.com/identity/data/autobackup)
explains platform backup behavior; Google's
[order-management guidance](https://support.google.com/googleplay/android-developer/answer/2741495)
describes the seller tools.
