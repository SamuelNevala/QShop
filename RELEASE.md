# Release QShopper on Google Play

Current candidate: **0.1.0 / Android code 5**. Account identity verification is
confirmed; no app entry, production/upload key, store upload or public app release
has been completed. REL-001 stays open until the remaining steps below are done.

Selected: personal account, Finland, a one-time paid build, all eligible Play
markets and adult household shoppers. EUR 2.99 is proposed, not selected.

## 1. Finish account and app setup

- Complete any remaining physical-device verification shown in Console; an
  emulator cannot replace that task. [Account/device guidance](https://support.google.com/googleplay/android-developer/answer/14316361).
- Review the [creation declarations](reviews/REL-001-declarations.md), then create
  **QShopper**, **App**, **Paid**. Confirm package availability before the first
  upload: `shopper.nevala.com` is the existing permanent package identity.
- Finish the [regional checklist](store/google-play/REGIONAL_CHECKLIST.md): accurate
  trader declaration, merchant profile, public contacts/terms, Japan payment tasks,
  age-rule applicability and final eligible country roster. Identity verification
  does not complete these. [App setup](https://support.google.com/googleplay/android-developer/answer/9859152).
- The [app terms](store/google-play/TERMS.md), version 18 November 2026, now have
  a generated public page and landing link. Deployment verification is pending;
  use the live URL in Console only after verification. Trader/checkout tasks remain.

The [export review](reviews/REL-001-export.md) supports ordinary shopping-list
software, likely EAR99 if subject to the EAR, and identifies no encryption-specific
Finnish/EU authorization requirement for this candidate. It is not unrestricted
destination clearance or an agency ruling. The owner accepts the actual declarations.

## 2. Set up production signing

Use [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
for the store-delivered identity and a separate owner-controlled upload key.
Keep private keys outside the checkout/shared source tree, with encrypted backups;
keep passwords out of Git/scripts. Retain labelled public certificate fingerprints.

Run locally when ready; choose a new filename if a key already exists:

```powershell
$keyFolder = Join-Path $env:USERPROFILE '.android/keys'
New-Item -ItemType Directory -Force -Path $keyFolder
$uploadKey = Join-Path $keyFolder 'QShopper-upload.jks'
& "$env:JAVA_HOME/bin/keytool.exe" -genkeypair -v -storetype JKS -keystore $uploadKey -alias qshopper-upload -keyalg RSA -keysize 3072 -validity 10000
& "$env:JAVA_HOME/bin/keytool.exe" -exportcert -rfc -keystore $uploadKey -alias qshopper-upload -file (Join-Path $keyFolder 'QShopper-upload-certificate.pem')
```

These commands have not been run. Register the upload certificate in Console.

### Preserve existing lists

The current phone uses a debug certificate. A production/Play-signed build cannot
directly update it; a higher version code does not bridge different certificates.
Keep the compatible debug build until a tested migration exists. There is no
public export/import flow; a SQLite backup alone does not prove restore into a
non-debuggable app. Do not uninstall to bypass this error.

## 3. Build and verify

Install the kit in [BUILDING.md](BUILDING.md)/[ANDROID.md](ANDROID.md).
MinSizeRel uses ThinLTO, R8 and resource shrinking:

```powershell
$sdk = Join-Path $env:LOCALAPPDATA 'Android/Sdk'
./build-android.ps1 -Architecture arm64 -Configuration MinSizeRel -SdkRoot $sdk -VerifyPackage
./build-android.ps1 -Architecture arm64 -Configuration MinSizeRel -AppBundle -SdkRoot $sdk -VerifyPackage -Bundletool /path/to/bundletool.jar
```

Outputs: `dist/QShopper-arm64-release-unsigned.apk` and `.aab`. They need signing
before installation/upload. Obtain bundletool from [Google](https://github.com/google/bundletool/releases);
the validated version is 1.18.3. Use `-Python` to select the verification interpreter.

Checks cover payload/dependency closure, unwanted modules/tooling, manifest,
permissions, native stripping and 16 KB ELF/ZIP alignment. Recheck generated
metadata on SDK upgrades: this kit emits target **37**, compile **36**.
Alignment is not a 16 KB runtime test. Retain API 28, API 37 and 16 KB runtime
checks as gaps until exercised; see [Android page-size guidance](https://developer.android.com/guide/practices/page-sizes).

The code-5 ARM64 APK is **24,627,266 bytes / 40 native libraries**, down about
61% from the 63,317,333-byte baseline. Ten backgrounds remain. Required backing
libraries and seven QML/style plugins stay; 13 optional wrappers were removed and
tested cumulatively. The explicit inventory is `android/runtime-libraries.txt`.
Repeat the optional-plugin matrix on a Qt upgrade. APK, installed and Play
download sizes are different measurements.

Run [Windows and Android tests](tests/README.md), including genuine non-debuggable
Release on disposable emulator data. Release blocks Debug redirection/run-as;
debug-key-signed Release test APKs are test artifacts, not production signing.
The 9 November shopping trip succeeded. UI-035 is phone-confirmed; QA-001/QA-002
physical details and UX-007's 110% sensitivity trip remain separate.

## 4. Complete public material

- Accept the [listing copy](store/google-play/README.md), price, feature graphic
  and actual phone screenshots. Store icon is prepared. Complete access, ads,
  intended audience and the separate IARC rating questionnaire.
- Review [privacy evidence](reviews/REL-001-privacy.md)/[Data safety](store/google-play/data-safety.md)
  against the final package. Unneeded Internet/network/storage permissions are
  removed; Android backup remains enabled. No collection is not an exemption
  from applicable policy/form requirements.
- Use the [public privacy policy](https://samuelnevala.github.io/QShop/privacy-policy.html),
  anonymously verified against accepted HTML on 12 November. Saving it in Console
  is pending. Canonical text is app/privacy-policy.txt; regenerate/check with
  `python tools/export-privacy-policy.py --check` after generating changes.
- Publish and verify **all matching source-set files** under
  [SOURCE_DISTRIBUTION.md](SOURCE_DISTRIBUTION.md)/[LICENSING.md](LICENSING.md).
  Local archives and a moving master branch do not complete source delivery.
  Existing candidate snapshots predate this documentation cleanup: regenerate
  after acceptance and inspect before publishing.

GitHub Pages serves `master:/docs`; changing that folder on a pushed commit deploys
it. Terms are generated from store/google-play/TERMS.md with
`python tools/export-terms.py`; `--check` verifies the HTML matches. Recheck the
live page after deployment before using its URL in Console.

## 5. Sign, test through Play, then submit

Sign a copy with the registered upload key; let jarsigner prompt for its password:

```powershell
& "$env:JAVA_HOME/bin/jarsigner.exe" -keystore $uploadKey -sigalg SHA256withRSA -digestalg SHA-256 -signedjar dist/QShopper-arm64-release-upload.aab dist/QShopper-arm64-release-unsigned.aab qshopper-upload
& "$env:JAVA_HOME/bin/jarsigner.exe" -verify -verbose -certs dist/QShopper-arm64-release-upload.aab
```

Verify the signer fingerprint, then use the internal track to inspect Play's
generated APKs, certificates and device report. For this new personal account,
the documented production-access route requires **12 closed-test testers opted
in continuously for 14 days**, real feedback and a production-access application;
approval is not automatic. Follow the actual Console eligibility prompts and
[current testing guidance](https://support.google.com/googleplay/android-developer/answer/14151465).

For each shared update, increase Android code and keep the revision, toolchain,
hashes, source manifest, public certificates, test/package reports, symbols and R8
map. Tag accepted releases under [versioning](README.md#versions). Revalidate
artifact-changing edits. Review the final country/rollout/submission summary and
obtain owner publication approval. Retain an update and data-loss/crash response plan.
