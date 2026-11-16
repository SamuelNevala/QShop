# QShopper Android export review

Reviewed **15 November 2026** for the retained **0.1.0 / Android code 5 ARM64**
APK/AAB. This is a documented technical self-assessment for the owner's review,
not a BIS classification ruling or acceptance of a Google declaration.

## Working conclusion

The evidence supports treating this candidate as ordinary shopping-list software,
rather than a product providing confidentiality encryption. **EAR99 is the likely
working designation if the product is subject to the US EAR and no other CCL
entry applies**. This is an inference from the fixed product's functionality and
the official guidance, not a claim that GPL software is automatically outside
export rules. No basis for an encryption filing was identified for this build.

The owner confirmed **Finland** as the publishing country and **all eligible
Google Play markets** as the initial market scope on 15 November 2026.
Eligibility includes paid-app availability, applicable Finnish/EU/US restrictions
and any regional publishing requirements. This is the selected launch scope,
not an unrestricted worldwide-export authorization. No declaration, filing,
message to an authority or Console setting was submitted.

## Evidence from the actual candidate

Both unsigned artifacts still match their verified source-input records: **94
tracked inputs are unchanged**. The APK and AAB contain the same 40 native-library
payload. Their SHA-256 hashes are:

| Artifact | SHA-256 |
| --- | --- |
| ARM64 APK | `e6d6c0f0c94f21122dda06eb21d5e28695b14149e4c39abc57553885773eef22` |
| ARM64 AAB | `c7a626f9a591d57b14c892bb424894e75fb7da25e19d6bc20d9e0581027577d4` |

| Area | Observed facts and interpretation |
| --- | --- |
| App functionality | Local shopping lists, editing/order, swipe checks/deletion, themes and offline documents. No VPN, encrypted messaging, secure vault, cryptanalysis, intrusion, surveillance or military-specific feature was found |
| Storage | Production code opens ordinary `QSQLITE` without a database key/password. No SQLCipher library or `sqlite3_key`/`sqlite3_rekey` dynamic symbol was found. Android's own storage/backup protection is separate platform behavior |
| Connections | No production app calls to encryption/TLS/network clients were found. QML starts from a local `qrc:` URL; policy/license readers use bundled resources. Release declares only AndroidX's internal signature receiver permission, with no INTERNET permission |
| Native libraries | Qt Core exports `QCryptographicHash` and `QMessageAuthenticationCode`. Qt Network retains `QSsl*` APIs. No packaged TLS backend, libssl/libcrypto, sodium, mbedTLS or SQLCipher library was found; no direct OpenSSL/AES/ChaCha dynamic symbols matched the audit patterns |
| Android bytecode | Retains KeyStore, certificate and TrustManager references. These were traced to Qt's `QtNative.getSSLCertificates()`, which enumerates accepted system issuers. No javax.crypto or SSLContext/SSLSocket reference was found by the DEX-string inspection |
| Signing | APK signatures authenticate the package and protect integrity. They do not make shopping-list data a confidentiality-encryption feature. Developer build/signing tools and Android/Play services are distinguished from the packaged app |

The exact Qt Base source at `025bdad181de241e81bf853c8a2d7bf3d19261a9`
shows that SSL-socket support depends on an available backend implementing it.
The certificate enumeration method is in
[QtNative.java](https://github.com/qt/qtbase/blob/025bdad181de241e81bf853c8a2d7bf3d19261a9/src/android/jar/src/org/qtproject/qt/android/QtNative.java).
API names alone were not treated as evidence of a usable encryption service.
Conversely, missing symbols/permissions alone do not prove the absence of all
cryptographic code; the conclusion uses the source, dependency and binary facts
together. The scan is not a complete formal code/call-graph proof.

## How the rules apply

[Google's export guidance](https://support.google.com/googleplay/android-developer/answer/113770)
explains why distribution through its US servers can bring an app under US
export rules, including an open-source app using another component's crypto.
It also states that Play blocks downloads to embargoed countries. That does not
replace the developer's review of the actual distribution.

[BIS's confidentiality guidance](https://www.bis.gov/learn-support/encryption-controls/cryptography-for-data-confidentiality)
distinguishes confidentiality encryption from authentication, digital signatures
and data integrity. Hash/HMAC and package-signature findings do not establish a
confidentiality-encryption product. The app-specific review found no matching
controlled security or other specialized CCL purpose. The current
[CCL, including 5A002, 5D002, 5D992 and EAR99](https://www.bis.gov/regulations/ear/774)
is the classification reference; 5D992.c is not a default label for every app
that contains a hash function or a Qt library.

Do not file a source-code notification simply because the project is open
source. The current [§742.15(b)](https://www.bis.gov/regulations/ear/742) limits its
source-notification requirement to the specified non-standard cryptography.
No such cryptography was identified here. A future confidentiality-encryption
feature would require a fresh product assessment; the
[public-availability overview](https://www.bis.gov/learn-support/encryption-controls/encryption-items-not-subject-to-ear)
is not a blanket exemption for a newly combined or paid application.

[Qt's export page](https://doc.qt.io/qt-6/exportcontrols.html) supplies vendor
information for its framework, while requiring customers to assess their own
product. It supports the dependency record rather than classifying QShopper.
The local source candidate includes unchanged pinned Qt archives and their
source/configuration metadata. Preserve those records and reconsider the source
publication analysis if cryptographic functionality changes.

## Finland and the selected markets

Finland's [export-control guidance](https://um.fi/export-control-guidelines-for-companies)
covers EU-listed and national-list items, as well as certain end-use and sanctions
cases. In the EU [2021/821 Annex I, consolidated 21 September 2026](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:02021R0821-20260921),
5A002/5D002 concern the specified security/encryption capabilities; authentication,
digital signatures and integrity have a different treatment from confidentiality.
The fixed app's evidence above identifies no such confidentiality feature or
other specialized controlled purpose. **No encryption-specific Finnish/EU
authorization requirement was identified for this candidate.** This is the
technical assessment, not a ruling on every possible transaction or recipient.

The market preference is all eligible markets, rather than a Finland/EU-only
launch. At rollout, use the current Console options and
[paid-app availability](https://support.google.com/googleplay/answer/143779?hl=en),
complete Google's [regional requirements](https://support.google.com/googleplay/android-developer/answer/6223646?hl=en),
and respect applicable [Finnish/EU sanctions](https://um.fi/international-sanctions).
Store availability alone does not establish legal eligibility. Keep the actual
accepted country roster with the release record; review later expansions or
newly available countries rather than treating this preference as perpetual
authorization. Countries and regional declarations have not been configured.

## Owner decisions and release procedure

1. Publishing country and initial market preference are confirmed as above.
   Retain the Finland-specific assessment and finish the actual country roster
   and regional requirements before production. The
   [Ministry for Foreign Affairs](https://um.fi/export-control) is Finland's
   dual-use export authority for any unresolved classification/transaction issue.
2. Review destination/end-user/end-use restrictions for the selected scope.
   [BIS guidance](https://www.bis.gov/licensing/guidance-on-end-user-and-end-use-controls-and-us-person-controls)
   explains why EAR99 does not remove every licensing restriction. Do not use
   the working designation as permission to bypass Play's country restrictions
   or as approval of separate APK/support transfers to restricted recipients.
3. Keep this review with the accepted artifact, dependency inventory and source
   manifest. Regenerate the unpublished source candidate after accepting the
   final revision; the existing candidate snapshot predates this documentation.
   Complete [source delivery](REL-001-licensing.md) before store distribution.
4. Recheck changes to TLS/cloud/sync, encrypted storage, payments/security SDKs,
   cryptographic functionality or destinations. Seek a classification decision
   if material uncertainty remains; [BIS](https://www.bis.gov/contact-us) offers
   counselor guidance and classification requests. No inquiry has been sent.
5. The owner reviews/accepts the actual Console export declaration. This review
   does not settle the separate Developer Programme Policies or signing terms.

## Verification record

Read-only analysis is under `out/rel001/export`: `inspect-artifact.py`,
`artifact-evidence.json`, `artifact-check.txt`, `application-source-search.txt`,
the exact Qt certificate-method source and TLS-backend source excerpts.
Binary/source binding, all 40 native libraries, APK/AAB payload equality and DEX
security references were checked. No application, build, signing or permission
change was made for this review; app/UI tests were not rerun. The earlier
[license audit's](REL-001-licensing.md) passing checks remain historical evidence.
