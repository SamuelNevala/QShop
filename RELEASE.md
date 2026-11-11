# QShopper release preparation

Checked against official guidance on **8 November 2026**. The selected target
is **Google Play**, with APKs for development/testing. Samuel will publish through
a **new personal developer account**. No production/upload key exists yet.
The app is currently **0.1.0, Android code 3**. Account creation, signing-key
enrolment, uploads and publication have not been performed.

## 1. Create your personal Play Console account

1. Sign in with the Google account you intend to own QShopper long term. Open
   [Play Console registration](https://play.google.com/console/signup).
2. Choose **Personal** when asked for the account type. Enter your developer
   display name, legal identity/address and the requested contact details.
3. Review the Developer Distribution Agreement and pay the **one-time US$25
   registration fee**. Google requires an adult account owner and a supported
   payment card. Follow the actual signup prompts if their order differs.
4. Complete the identity checks shown in the account dashboard. Google may ask
   for a government ID. Verify your contact email/phone and developer email.
5. Complete the Android-device task: on the Console Home page, open **Verify
   that you have access to an Android mobile device**, scan its QR code, install
   the Play Console app on your physical phone and sign in as the same owner.
   Select the developer account and follow **Verify**. The device must be a
   non-rooted physical Android 10+ device; the emulator cannot do this step.

Use an email address suitable for public app support. For personal accounts,
Google displays the legal name, country and developer email; monetization or
regional requirements can expose additional address/contact information. Review
the profile preview and regional declarations before completing them.

References: [account registration and fee](https://support.google.com/googleplay/android-developer/answer/6112435),
[personal-account identity/contact details](https://support.google.com/googleplay/android-developer/answer/13628312),
[physical-device verification](https://support.google.com/googleplay/android-developer/answer/14316361).

## 2. Create the QShopper app entry

In Play Console, use **Create app**. Select QShopper, its default language,
**App**, the intended free/paid choice and a support email. Complete the displayed
declarations. Confirm availability/ownership of **`shopper.nevala.com`** before
the first upload: this is the existing package ID, and Play package names are
permanent. Pricing, countries, target audience and public support details still
need the owner's choices.

See [Create and set up your app](https://support.google.com/googleplay/android-developer/answer/9859152).

## 3. Establish signing ownership

Recommended setup for this new Play app:

- Let **Play App Signing** generate/manage the app-signing identity used for
  APKs delivered by Google Play. Follow the current new-app enrolment prompts.
- Create a separate **upload key** owned by Samuel. It signs AAB uploads; it
  is different from the Play app-signing key and the existing debug key.
- Keep the keystore outside the repository/shared OneDrive source tree, with an
  encrypted backup and recoverable owner-controlled credentials. Record its
  alias and public certificate fingerprint; keep passwords out of scripts/Git.
- Register the upload certificate in Console. Keep the Play app-signing and
  upload certificate fingerprints separately labelled in the release record.

[Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
explains the key roles, new-app enrolment and upload-key recovery.

When ready to create the upload key, run this locally and answer its interactive
password/identity prompts. This command has not been run by the agent:

```powershell
$keyFolder = Join-Path $env:USERPROFILE '.android/keys'
New-Item -ItemType Directory -Force -Path $keyFolder
$uploadKey = Join-Path $keyFolder 'QShopper-upload.jks'
& "$env:JAVA_HOME/bin/keytool.exe" -genkeypair -v -storetype JKS -keystore $uploadKey -alias qshopper-upload -keyalg RSA -keysize 3072 -validity 10000
& "$env:JAVA_HOME/bin/keytool.exe" -exportcert -rfc -keystore $uploadKey -alias qshopper-upload -file (Join-Path $keyFolder 'QShopper-upload-certificate.pem')
```

Use a new filename if a keystore already exists; never overwrite an established
identity. See the [JDK keytool reference](https://docs.oracle.com/en/java/javase/21/docs/specs/man/keytool.html).

## 4. Preserve existing development lists

The current phone installation uses the shared **debug certificate**. An APK
signed with the new production identity cannot directly update it. Neither the
upload key nor changing the version code bridges that certificate difference.
See [Android update signing](https://developer.android.com/studio/publish/app-signing).

Use the compatible debug-signed build for ongoing physical shopping tests.
Before moving that phone to the Play installation, prepare and verify a list
export/import or another explicitly tested migration route. QShopper currently
has no public export/import flow. A private SQLite backup alone does not prove
that the non-debuggable production app can restore it. Preserve the installed
app and its data until this is resolved; do not uninstall it as a signing fix.

Local **Release test APKs** can use the existing debug certificate while keeping
Release code and a non-debuggable manifest. Those are test artifacts, never Play
production signing. Builds downloaded from a Play test track use Play's signing
identity and test the real distribution/update path.

## 5. Build and validate unsigned release artifacts

Use the normal installed Qt 6.12 Android kits, SDK/NDK and JDK 21 described in
[ANDROID.md](ANDROID.md). The size profile is **MinSizeRel** with native ThinLTO,
R8 Java optimization and Android resource shrinking. Debug builds retain their
existing behavior. Production preparation always starts unsigned.

```powershell
./build-android.ps1 -Architecture arm64 -Configuration MinSizeRel -SdkRoot C:/android/sdk -VerifyPackage
./build-android.ps1 -Architecture arm64 -Configuration MinSizeRel -AppBundle -SdkRoot C:/android/sdk -VerifyPackage -Bundletool out/rel001/bundletool-all-1.18.3.jar
```

Outputs are `dist/QShopper-arm64-release-unsigned.apk` and
`dist/QShopper-arm64-release-unsigned.aab`. They are not install/upload-ready.
The helper uses separate caches, keeping the normal Debug APKs intact. Use
`-Python` to select an interpreter, `-Jobs` to limit build load and
`-Configuration Release` for the ordinary optimized-speed baseline.

Obtain bundletool from [Google's official release](https://github.com/google/bundletool/releases/tag/1.18.3).
The checked 1.18.3 JAR SHA-256 is
`a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29`.
It is a local verification tool, not an app dependency.

Verification checks the actual manifest/version, non-debuggable state, native
dependency closure, absence of unused/test/QML-tooling payload, stripped delivered
libraries, ELF and APK ZIP 16 KB alignment, and AAB configuration/structure.
The installed kit currently emits target SDK **37** with compile SDK **36**;
this pass preserves that existing target behavior. Check the generated metadata
again on kit/SDK upgrades. The current Play minimum for new phone apps is API 36;
see [target-API policy](https://support.google.com/googleplay/android-developer/answer/11926878).
[Android's 16 KB guidance](https://developer.android.com/guide/practices/page-sizes)
also requires native-runtime testing on a 16 KB device/image before claiming
full compatibility; binary alignment alone is not that runtime test.

Qt's [Android deployment tool](https://doc.qt.io/qt-6/android-deploy-qt-tool.html)
builds the packages; [R8 guidance](https://developer.android.com/topic/performance/app-optimization/enable-app-optimization)
describes Java/resource optimization. Qt JNI entry points and dynamically named
bootstrap resources are explicitly retained.

Standalone Release APKs compress native libraries, which Android extracts during
installation. This minimizes the APK file at the cost of extra installed storage
and extraction work. Play bundles use the independent Gradle variant policy to
keep their generated native APK splits uncompressed/mmap-friendly and 16 KB
aligned. A universal bundletool APK is not the device-targeted split layout.

### Measured size and required libraries

| ARM64 package | Bytes | Native libraries |
| --- | ---: | ---: |
| Original Release baseline, code 2 | 63,317,333 | 53 |
| Final standalone Release APK, code 3, unsigned | 24,585,386 | 40 |

This is about a **61% APK reduction** with the ten full-size backgrounds and
existing UI features retained. Java DEX shrank from 5,298,532 to 267,312 bytes.
The remaining native inventory is explicit in `android/runtime-libraries.txt`.
Network, WorkerScript and vector-generator backing libraries remain because
retained Qt libraries need them. Seven required QML/style plugins also remain.

Each of 13 Qt-declared optional wrapper plugins was removed cumulatively and
tested on native Android, followed by a final combined smoke test. A deliberately
removed required Material plugin makes that same test fail. The wrappers can be
omitted because their backing libraries are already loaded; see Qt's
[optional plugin semantics](https://doc.qt.io/qt-6/qtqml-modules-qmldir.html#plugin-declaration).
The Release artifact check fails the original extra-wrapper payload and enforces
the final required-library inventory. Repeat the removal matrix on a Qt upgrade.

The APK is not a claim of the theoretical smallest Qt build. Larger reductions
would need a separate custom/static Qt build assessment or product/asset changes.

## 6. Verify behavior and size

- Run the normal Windows workflow and affected native Android interactions.
- Test genuine non-debuggable Release code on a disposable emulator, including
  entry, Return, drawer/themes, offline notices/logos, swipes, Undo and restart.
  Release blocks `run-as` and Qt debug intent environment injection. Its harness
  therefore uses a fresh temporary emulator userdata disk and only its own app
  data, without adding a production test backdoor.
- Retain the native-library inventory and measured before/after size report.
  Preserve ELF dependencies and required QML/style plugins. Recheck any optional
  plugin removal one at a time and verify the final combination.
- Keep 16 KB runtime coverage and API 28 compatibility as explicit readiness
  checks if only the API 36/4 KB emulator has run. Include an API 37 device run
  matching the current target SDK before declaring the production matrix complete.
- The **Monday, 9 November 2026** shopping run succeeded overall, reported on
  11 November. UI-035 is fixed with phone confirmation; UX-007 awaits
  the next trip at 110% sensitivity. Natural-speech details and QA-002's specific
  physical measurement/readability checks remain separate.

AAB upload size, locally installed APK size and Play's compressed download size
are different measurements. Native symbols/R8 maps can be retained in bundle
metadata for diagnostics without being delivered as app runtime payload.

## 7. Sign the accepted AAB for upload

After creating/registering the upload key, sign a copy of the verified unsigned
bundle. Keep the original and let jarsigner prompt for the secret:

```powershell
& "$env:JAVA_HOME/bin/jarsigner.exe" -keystore $uploadKey -sigalg SHA256withRSA -digestalg SHA-256 -signedjar dist/QShopper-arm64-release-upload.aab dist/QShopper-arm64-release-unsigned.aab qshopper-upload
& "$env:JAVA_HOME/bin/jarsigner.exe" -verify -verbose -certs dist/QShopper-arm64-release-upload.aab
```

Check the resulting signer fingerprint against the registered upload certificate.
See the [JDK jarsigner reference](https://docs.oracle.com/en/java/javase/21/docs/specs/man/jarsigner.html).
Keep signing a separate step from ordinary local builds.

## 8. Complete the store and distribution material

- Prepare the app name, short/full description, support contact and category.
  Supply a 512 x 512 store icon, feature graphic and current phone screenshots.
  The store icon needs the [Play icon specifications](https://developer.android.com/distribute/google-play/resources/icon-design-specifications);
  it is a separate export from the round Android launcher artwork.
  See [store asset requirements](https://support.google.com/googleplay/android-developer/answer/9866151).
- Complete app access, ads, age/content rating, target audience and regional
  declarations from the actual product and the owner's decisions.
- Audit the final permissions, local SQLite/settings, Android backup policy and
  third-party code before answering Data safety. Qt currently auto-adds Internet,
  network-state and legacy external-storage permissions. Native network libraries
  in the payload do not by themselves establish data collection.
- Prepare a public privacy-policy URL and consistent in-app access. Even an app
  declaring no collection still needs the applicable Data safety form/privacy
  policy for closed/production distribution. Follow [Data safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469).
- Follow [LICENSING.md](LICENSING.md): exact corresponding project/Qt source,
  notices and required installation/relinking information must accompany the
  distributed build arrangement. Publish the matching source revision before
  distributing public binaries; review the actual GPL/LGPL obligations there.

## 9. Test through Play, then request production access

Start with the internal test track and inspect Play's generated APKs, report,
signing certificates and device catalog. Then set up a **closed test** and invite
at least **12 testers**. They must stay opted in **continuously for 14 days**;
the Console must show eligibility before applying for production access. Testers
should actually use QShopper and provide feedback. An internal test or emulator
run does not replace this requirement for the new personal account.

After eligibility, complete the production-access application, including the
testing/feedback/readiness questions. Approval is not automatic after day 14.
See [new-personal-account testing](https://support.google.com/googleplay/android-developer/answer/14151465).

## 10. Retain evidence and publish only the accepted build

Before upload, increase the Android code for each new shared update, retain
the source revision/toolchain, artifact hashes, public signer fingerprints,
package reports, native symbols and R8 mapping. Use a Git tag for an accepted
release, following [README versioning](README.md#versions). Repeat affected tests
after any artifact-changing edit; do not reuse an old binary's pass.

Before production, resolve the readiness gaps above, select countries/rollout
and release notes, inspect the exact Console review summary and obtain the
owner's go-ahead for submission/publication. Keep a tested update procedure and
a response plan for data-loss/crash reports. REL-001 remains open while these
account, signing, migration, validation and submission steps are incomplete.
