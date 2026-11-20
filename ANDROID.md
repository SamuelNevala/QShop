# Android builds

Install/configure the tools in [BUILDING.md](BUILDING.md). The app package is
`shopper.nevala.com`, version **0.1.0 / code 5**, minimum Android 9/API 28.
Compile SDK is 36; the current APK targets API 37. Gradle downloads dependencies
on the first build.

## Build and install

From PowerShell in the checkout:

```powershell
./build-android.ps1 -Architecture arm64
$sdk = Join-Path $env:LOCALAPPDATA 'Android/Sdk'
& "$sdk/platform-tools/adb.exe" devices
& "$sdk/platform-tools/adb.exe" -s YOUR_DEVICE_SERIAL install -r dist/QShopper-arm64-debug.apk
```

Replace `YOUR_DEVICE_SERIAL` with the entry shown by `adb devices`. Enable USB
debugging and authorize the computer on the phone. Qt Creator can build and
install directly from the Android kit's Run configuration.

Defaults: Qt in `C:/Qt`, SDK under `%LOCALAPPDATA%/Android/Sdk`, NDK
27.2.12479018, Adoptium JDK 21. Override script parameters for other locations.
Use `-Architecture x86_64` for an emulator APK at `dist/QShopper-x86_64-debug.apk`.

## Updating an existing installation

Use the same signing certificate. When moving between development computers,
pass the original debug key stored **outside** the checkout:

```powershell
./build-android.ps1 -Architecture arm64 -DebugKeystore /path/to/debug.keystore
```

This option expects the standard Android debug alias/password. Source sharing
does not share each computer's default debug key. Production uses a separate
signing setup; preserve existing lists before a signing migration. Do not commit
keystores or passwords.

## Release and Play bundle

```powershell
./build-android.ps1 -Architecture arm64 -Configuration MinSizeRel -VerifyPackage
./build-android.ps1 -Architecture arm64 -Configuration MinSizeRel -AppBundle -VerifyPackage -Bundletool /path/to/bundletool.jar
```

Outputs are `dist/QShopper-arm64-release-unsigned.apk` and `.aab`. They need
appropriate test/upload signing. The helper deliberately rejects debug signing
and QML debugging for Release. `MinSizeRel` uses ThinLTO, R8 and resource shrinking;
`Release` is also available. See [RELEASE.md](RELEASE.md) for signing/publication.

## Package regression (DEV-008)

`-VerifyPackage` needs Python (`-Python` chooses the interpreter); bundle checks
also need the official bundletool JAR. It checks actual permissions, version,
native dependency closure, QML scan roots, 16 KB alignment, the selected runtime
inventory/notices and unchanged source inputs. Configuration alone is not proof
of the delivered payload.

Production lives in `app/`; tests and build copies must stay outside it. The
optimized payload keeps 40 required native libraries, JPEG, SQLite and Android's
platform/IME. Material, its Basic fallback and the Fusion editor are retained.
Optional TLS, image, desktop-keyboard, unused style and profiling plugins are
excluded through Qt's deployment API. Ordinary Debug/Release need no Internet or
storage permission; explicit development `-QmlDebug` is the only Internet opt-in.
Android backup remains enabled. Notices remain complete and offline.

## Emulator tests

Create a dedicated API-36 x86_64 phone AVD with a Google Play image, English
QWERTY Gboard and gesture navigation. Use host GPU rendering. Find its serial
with `adb devices`; install the x86_64 Debug APK there, then follow
[tests/README.md](tests/README.md#android-tests). Tests use disposable app data;
never run destructive Release tests on normal phone data.

## Platform behavior

- Android Back closes the foremost About/privacy/popup layer, then drawer,
  keyboard, and edit mode. Shopping-mode Back backgrounds the app. Hiding the
  keyboard keeps the draft and releases text focus; tapping the editor reopens
  entry. Leaving edit mode discards the draft/restores its original.
- `adjustResize` keeps the movable editor above the system IME. Return keeps
  entry open. A 40-row cache plus retained editor supports long-list scrolling.
- The phone app requests portrait. Android can override this on large displays;
  API-37 targeting has no API-36 large-screen opt-out. Phone testing does not
  certify tablet/foldable or multi-window behavior.

Expected behavior: [DESIGN.md](DESIGN.md). Regression evidence and resolved dates
remain in [tickets](tickets/) and the [interaction inventory](tests/INTERACTIONS.md).
