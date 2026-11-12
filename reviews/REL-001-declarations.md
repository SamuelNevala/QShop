# Play Console declaration review

Reviewed 12 November 2026 against the local app, retained Release APK and current
official guidance. This is a readiness review, not Google approval or an export
classification. No declarations have been accepted on the owner's behalf.

Later on the same day, the [privacy implementation](REL-001-privacy.md) added
offline policy access and prepared the public page and Data safety answers.
Fresh code-4 packages remove the three unnecessary permissions. The initial
findings below preserve the original code-3 review; the table records current
remaining work.
Publication/verification of the policy URL, final Console answers and the
source/license/export/signing gates remain open.

| Declaration | Assessment | Remaining work |
| --- | --- | --- |
| Developer Programme Policies | Not yet established as fully compliant | Publish/verify the prepared policy URL; finalize Data safety and remaining Console declarations; complete source/distribution-license review |
| Play App Signing terms | Technically compatible; owner acceptance of terms | Read/accept terms, then establish the upload key and Play app-signing identity for the accepted bundle |
| US export laws | No app-purpose encryption feature found; application-specific compliance not established | Review the complete distributed product and intended destinations using current export guidance; Qt's classification does not classify QShopper |

## Initial code-3 app findings

- Core lists are stored in local SQLite and preferences. No application-level
  HTTP client, analytics/ad SDK or microphone/camera access was found in the
  production C++/QML search. Keyboard dictation belongs to the user's IME.
  This is source-review evidence, not a complete third-party traffic audit.
- The manifest enables Android backup (`allowBackup=true`). Privacy wording
  must account for platform backup rather than promise that shopping data can
  never leave the device.
- The retained ARM64 Release APK declares `INTERNET`, `ACCESS_NETWORK_STATE`
  and `WRITE_EXTERNAL_STORAGE`, plus the generated AndroidX receiver permission.
  They were verified using SDK `aapt2 dump permissions`, not inferred solely
  from the source manifest. Review/remove permissions that the app does not need;
  their presence alone does not prove data collection or a policy violation.
- No privacy-policy file, URL or in-app privacy entry was found. About currently
  shows the offline Qt/Font Awesome notices. Google's User Data policy requires
  privacy-policy access in the app and Console even without sensitive-data access.
- Root GPL project notices and the third-party notice reader exist. Exact
  corresponding-source and Qt installation/relinking arrangements, and the
  remaining Android Java/Maven notices, are still release-audit work described
  in [LICENSING.md](../LICENSING.md). Open source and charging for a build are
  not themselves evidence of a Play policy violation.
- The Release APK/AAB preparation has passed its structural/package tests, but
  production/upload keys have not been created. Accepting Play App Signing's
  terms is a separate owner action from supplying the eventual signing keys.

The APK reviewed here is the retained 0.1.0/code-3 Release preparation artifact
from 8 November. UI-035 was subsequently fixed and phone-confirmed in commit
`0dbad9f`; repeat the final artifact/manifest review when rebuilding for upload.

## Export assessment limits

No explicit app-level encryption functionality was found. The package retains
Qt Network as a native dependency and omits optional TLS provider plugins.
Absence of an OpenSSL/TLS plugin is not a blanket claim that all bundled code
or platform calls lack cryptographic capability.

Qt's current documentation lists its framework libraries as not controlled,
while explicitly requiring customers to classify their own exported products.
Google also explains that hosting/distribution from its US servers can bring
an app under US export rules, including open-source apps. Do not infer an ECCN,
exemption, filing requirement or unrestricted destination list from this source
scan. No export notification or filing has been made.

## Sources and next work

- [Google User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311): privacy-policy and data-handling requirements.
- [Google permissions policy](https://support.google.com/googleplay/android-developer/answer/16558241): permissions must support current advertised functionality.
- [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756): Google-managed signing and the separate upload key.
- [Google export guidance](https://support.google.com/googleplay/android-developer/answer/113770): developer responsibility and distribution through US servers.
- [Qt 6.12 export guidance](https://doc.qt.io/qt-6/exportcontrols.html): framework classification and its limits for customer products.

The privacy/data/permission implementation is now prepared locally; see the
linked audit for verification and policy-publication steps. Next finish the
remaining release declarations and source/license delivery checks before
seeking publication.
Creating a Console draft is separate from uploading or publishing a release.
