# QShopper privacy and permissions audit

Work began 12 November 2026 under REL-001. The owner selected
**samuel.nevala@gmail.com** as the public support/privacy address and GitHub Pages
in `SamuelNevala/QShop` as the policy destination. Price remains undecided;
EUR 2.99 is a proposal. No Play declarations have been submitted.

## Data paths

| Data or facility | Implementation and recipient | Policy treatment |
| --- | --- | --- |
| Shopping text, order, checks and list IDs | `app/main.cpp`, `model.cpp`: SQLite in `QStandardPaths::AppDataLocation`, no app network client | Device-private data; developer has no remote shopping-list copy |
| Theme/list selection and other preferences | Qt Settings, normal Android private preferences | Local preferences, eligible for platform backup |
| Unsubmitted editor text | InputDelegate's field and native IME | Keyboard/provider controls composition and voice typing; no app microphone feature |
| Temporary Undo | Model/UndoRemove process state; removed rows are recoverable while pending | Temporary recovery, not a permanent server history or secure-erasure guarantee |
| Android backup/device transfer | Manifest keeps `allowBackup=true`; app-private files/preferences are eligible | Provider/system settings govern transmission, restore and retention; no developer access |
| Purchases | Paid download through Google Play, no Billing SDK in app | Google processes payment; developer may receive order/transaction records in seller tools |
| System diagnostics | Qt/Android logging and possible Android/Play platform reports | No separate developer analytics/crash SDK; platform processing is described separately |
| Support | User's chosen email to the developer | Address/message/voluntary attachments used for support, purchases and legal obligations |
| Public policy/source pages | GitHub Pages and GitHub | Browser/hosting-provider processing differs from the bundled offline reader |

The production C++/QML search found no HTTP client, remote content URL, ad/analytics
SDK, microphone/camera/location API or in-app payment integration. The only new
document load is a fixed packaged `privacy-policy.txt` resource. The policy's
body does not need an app network connection. The app has no account-creation
flow and no developer-operated service to sync or receive shopping data.

## Dependencies

The actual Gradle `debugRuntimeClasspath` and final `releaseRuntimeClasspath`
reports are retained at `out/rel001/privacy/gradle-dependencies.txt` and
`gradle-release-dependencies.txt`. The roots are Qt's packaged bridge
JARs, AndroidX Core 1.17.0 and Kotlin stdlib 2.2.10. Transitives cover AndroidX
annotations/collections/concurrency/core-viewtree/interpolator/lifecycle/arch,
profile installation/startup/tracing/versioned parcelables, Kotlin coroutines,
Guava ListenableFuture and JSpecify annotations. No Firebase, ad, Google Analytics,
Crashlytics or Play Billing dependency appears in that graph.

Qt bridge JARs cover platform, Quick, Network and NetworkInformationBackend.
Native Qt framework and bundled codecs/SQLite remain in the explicit package
inventory. Qt Network is a required backing library; removing permissions does
not remove that dependency. These bridge/runtime dependencies are not treated
as proof of telemetry simply because networking APIs exist in them.

This review combines source/dependency/manifest evidence with native execution.
It is not a general certification of every dormant instruction in Qt. The
default app's absent Internet permission provides an additional platform boundary
against direct network traffic; separately controlled system services remain.

## Permission selection

Before: Qt Core's dependency metadata requests `INTERNET` and
`WRITE_EXTERNAL_STORAGE`; Qt Network requests `ACCESS_NETWORK_STATE`. The
unmodified APK declares all three despite private storage/local resources.
The strengthened real-APK regression fails that original artifact.

After: the application manifest deliberately omits Qt's generic permission
insertion placeholder, as supported by Qt's manifest configuration workflow.
Only explicit app needs are declared. Ordinary Debug and Release/MinSizeRel
expect **only** AndroidX's generated signature permission
`shopper.nevala.com.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. This protects
internal receiver delivery; it grants no access to user data or network traffic.

Explicit non-Release `-QmlDebug` additionally declares `INTERNET` for the remote
development connection. Release excludes that facility regardless of the option.
This exception is checked in the package regression and is not a store artifact.
The ordinary rebuild after opt-in must remove both tooling and Internet access.

Android backup stays enabled. We did not change it merely to simplify the policy.
No broad storage access is needed for the private database or preferences; native
tests must retain list persistence, entry, theme selection and offline readers.

## Policy and UI

`app/privacy-policy.txt` is the canonical English policy. The new drawer About
section offers Licenses and Privacy policy. The privacy dialog reads the small
local text through Qt's built-in TextDocument source API, with read-only,
non-selectable TextArea attached to a Flickable. It preserves the large license
reader's virtualized paragraphs; it does not replace that reader with TextArea.
View owns the privacy dialog's actual safe-area geometry. Back/Close dismiss it
before the drawer and preserve draft/list state. Qt's TextDocument source API is
technology preview; recheck it with kit upgrades.

`tools/export-privacy-policy.py` creates the public HTML from the same canonical
text; `--check` rejects a stale public copy. The static page contains no scripts,
third-party fonts or trackers. `docs/index.html` provides the Pages entry point.
Planned direct URL: `https://samuelnevala.github.io/QShop/privacy-policy.html`.
The page is prepared locally; publishing and a successful public fetch still
need to occur before entering that URL as a working policy in Console.

The [Data safety draft](../store/google-play/data-safety.md) maps proposed form
answers to these paths. It is not a submitted or approved label. Final provider
and delivered-artifact behavior must agree with the answers.

## Verification and remaining work

Before/after evidence is retained under `out/rel001/privacy`:

- The original real APK fails `tests/test_android_package.py` for all three
  unnecessary permissions (`permissions-before.txt`). Current ARM64/x86_64
  MinSizeRel APK/AAB pass package/dependency/inventory/16 KB checks. The explicit
  QML-debug build and the subsequent ordinary Debug rebuild also pass their
  respective permission/tooling contracts.
- The original desktop app fails both privacy-access cases; the original
  installed Android app fails at the missing Privacy policy button. Current
  `AboutLicenses::test_privacy_policy` covers both themes, body dragging without
  selection, opening latency, safe-area resizing, final-line reachability,
  Back/Close, no IME and exact retained draft/model contents.
- Android `test_about.py --privacy`: **16/16** pass offline in both themes,
  including both native Back edges, touch scrolling and retained draft/items.
  The existing complete license companion passes **26/26**. Frames of the
  policy and two-button About group were visually inspected.
- Android `test_entry.py`: **36/36** normal keyboard/list/catalog/settings and
  restart checks pass after permission removal. No physical microphone used.
- The genuine non-debuggable x86_64 MinSizeRel test APK passes **16/16** native
  Release checks: entry, themes/selectors, both notice tabs, bundled privacy,
  Back layering, delete/Undo, exact item restart persistence and no native/QML
  load failure. Test-signed ARM64 APK is available for owner phone review;
  no physical device was installed or operated.
- The public HTML's extracted reader text exactly matches the bundled policy;
  export `--check`, Python syntax, ticket JSON and QML format checks pass.
  Browser rendering of the local file was blocked by the browser URL policy;
  the live published page still needs browser/mobile review. No workaround was
  attempted. Generated HTML uses basic responsive system-font styling.

An initial Windows run failed the existing timed
`SwipeSensitivity::test_comfortable_swipe(edit_left)` case. The unchanged focused
suite then passed **11/11**, and the full UI suite passed **214/214** on rerun.
No swipe threshold/default/test assertion was changed or waived; the cause of
that intermittent timing failure was not established. Final Windows
configure/build and the full normal CTest workflow pass **23/23** entries,
including model, UI/flow/keyboard and native D3D11 WARP rendering. Both About
suites pass **13/13** records, including the new safe-area/end-line checks.
The evidence preserves the failed run.

Code 4's unsigned ARM64 APK is **24,604,514 bytes**, with the same **40** required
native libraries. The compatible shared-debug-key test-signed copy is
**24,620,205 bytes** (`dist/QShopper-arm64-release-test.apk`); it is not a
production-signed store artifact. Signer checks, artifact SHA-256 hashes and
verified task-owned emulator cleanup are retained alongside the test reports.

The owner accepted the prepared changes and requested a commit on 12 November 2026.
Pending: publication of the policy page, live Console answers,
final production-key/source-license/export/release gates and physical phone
confirmation of the new screen. A prepared policy is not overall Play approval.

References: [Qt manifest configuration](https://doc.qt.io/qt-6/android-manifest-file-configuration.html),
[Qt TextDocument](https://doc.qt.io/qt-6/qml-qtquick-textdocument.html),
[Android backup](https://developer.android.com/identity/data/autobackup),
[Google Data safety](https://support.google.com/googleplay/android-developer/answer/10787469),
[Google orders](https://support.google.com/googleplay/android-developer/answer/2741495).
