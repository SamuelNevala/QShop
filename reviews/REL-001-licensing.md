# Android license and source-delivery audit

Prepared 12–13 November 2026 for 0.1.0 / Android code 5. This records technical
evidence and release preparation. It does not accept Google agreements, classify
the exported application or certify every Play policy. REL-001 stays open.

## Selected arrangement and inventory

The owner's GPL-3.0-or-later choice is retained. Official Android builds select
Qt's GPLv3 option; Qt's separately licensed third-party code keeps its terms.
Charging for the official build does not remove recipients' GPL rights. See
[GNU's commercial distribution FAQ](https://www.gnu.org/licenses/gpl-faq.en.html#DoesTheGPLAllowMoney)
and [Qt's licensing overview](https://doc.qt.io/qt-6/licensing.html).

The actual optimized ARM64/x86_64 APKs retain 40 native libraries. The installed
Qt SPDX dependency closure selects 45 third-party attributions, all covered by
the existing Android Qt notice. No missing Qt attribution was found. The Qt
source commits recorded by the kit are:

| Module | Exact source commit |
| --- | --- |
| qtbase | `025bdad181de241e81bf853c8a2d7bf3d19261a9` |
| qtdeclarative | `4332fbbb4c340463dc8cee36dda0c85d932122d8` |
| qtsvg | `883a58532078d003cefef0a549bfe9f885ce41f5` |

The real Gradle Release runtime graph has 21 Maven artifacts: AndroidX,
Kotlin/coroutines, Guava, JSpecify and JetBrains components. The notice inventory
preserves their declared Apache 2.0 terms, upstream copyright/legal files and
source URLs/hashes. Guava's listenablefuture license comes from its parent POM.
Kotlin coroutines attribution is also retained from its pinned upstream license,
because its source JAR omits it. A source-header scan found no additional
non-Apache license markers in those Java/Kotlin sources; this scan complements
the actual POM/archive legal-file inspection.

`libc++_shared.so` is matched to NDK 27.2.12479018 by ELF build ID. Its complete
LLVM toolchain NOTICE is retained conservatively; this does not imply the
compiler/toolchain is shipped. Compiler revision and patch-source metadata are
preserved in the source set. Qt's bridge JAR sources belong to the exact Qt
archives. Font Awesome font/SVG, launcher art and Qt logo records remain intact;
no font/artwork asset or trademark permission was changed.

## Changes and repeatable verification

The offline reader adds an App tab with the complete project copyright/GPL text,
source/build link and Android runtime notices. The virtualized paragraph reader
is retained. Branded tabs place their logos above their captions so three equal
tabs fit without custom width arithmetic. CMake preserves the exact LF notice
content. Ordinary builds require neither Python nor notice downloads.

`build-android.ps1 -VerifyPackage` now checks the real resolved runtime graph,
artifact hashes and packaged C++ runtime against `android-runtime.json`. It also
records the binary hash and tracked source inputs, refusing source changes during
the build. The existing minimized permissions, QML payload isolation, native
dependency closure and 16 KB checks remain in force. Explicit Android/host Qt
prefix options support a separately rebuilt Qt installation.

Regressions and evidence under `out/rel001/licensing`:

- Original desktop reader: new App-tab test fails before implementation
  (`ui-before.txt`). Original Android code-4 APK fails
  `application_tab_available` (`android-before.txt`).
- Final Windows configure/build: model 105 records, About 14 offscreen and 14
  native D3D11 WARP records pass. Full bundled App text roundtrips exactly;
  copyright/GPL content is checked against the root files. Source-tool tests
  add four passing cases, also registered with CTest when Python is available.
- Native Android App reader: 26 passing checks across both themes, including
  actual offline headers/source directions, touch scrolling to the final
  paragraph, Back/Close, safe bounds and preserved isolated draft/database.
- Existing native Qt/Font Awesome reader: all 26 checks pass with three tabs.
- Genuine non-debuggable x86_64 Release: all 19 checks pass, including all three
  notice tabs, Android runtime ending, offline privacy, theme/selectors,
  entry/Undo and cold-restart preservation. No native/QML load failure is found.
- Runtime/NDK checks pass for the rebuilt Debug and optimized Release packages.
  Qt payload coverage is recorded in `qt-coverage.json`. Formatting checks pass.

Initial validation caught a generated CRLF mismatch and an attempted tab-width
binding loop; both were corrected before the final passing reader checks.
The native test was corrected to scroll to source directions rather than assume
the entire introduction fits on one screen. The missing-tab before result is
retained. No gesture sensitivity or shopping behavior was changed.

## Source delivery and remaining gate

[SOURCE_DISTRIBUTION.md](../SOURCE_DISTRIBUTION.md) documents user rebuilds,
separately named modified-app installation and selecting rebuilt Qt prefixes.
The source-set helper binds a candidate snapshot to the verified binary inputs
and prepares all tracked project files, exact complete Qt module archives,
Maven source JARs/POMs/legal files and NDK/Qt configuration metadata. It refuses
tracked private-key/data paths and non-regular Git entries; untracked build
outputs/private files are excluded. Every archive and project file has a hash.
Normal mode requires a clean checkout; dirty work is explicitly a candidate.

The candidate project archive was extracted into a fresh build copy, with every
file checked against its manifest. Changing only that copy's package ID to
`shopper.nevala.modified` produced a successful ordinary Debug APK build. It
installed alongside the original package, passed 26 native App-reader checks,
and left all six original isolated databases byte-for-byte unchanged. The build
used its own normal debug signing setup; the original private key was not needed.

Candidate source files are local preparation, not published Corresponding
Source. Before distributing the accepted store build, prepare its final manifest
and publish/verify all named source downloads with the binary/store source link.
Do not substitute a moving master link for an older build's exact sources.
Keep notices and modification/installation rights with the distribution.

The audit does not claim a full vendor Qt framework rebuild or identical binary
output. Qt's [Android source-build instructions](https://doc.qt.io/qt-6/android-building.html)
and the retained per-module configuration describe the framework prerequisites.
Existing private signing keys are neither necessary nor included for separately
named user builds. Final production signing and the actual Play distribution
arrangement remain release checks.

The phone-compatible ARM64 Release test APK is 24,640,685 bytes and uses the
existing shared debug certificate. Its unsigned APK is 24,627,266 bytes; the
verified ARM64 AAB is 32,016,374 bytes. Production signing has not been created.
The final AAB candidate source set is prepared under
`out/rel001/licensing/source-candidate-final`; its manifest records hashes and
explicitly marks it unpublished. The project-source rebuild uses the earlier
x86_64 candidate with the same app inputs. These local outputs are not Git files.

After source publication for the accepted build, the next declaration task is
the app-specific export assessment, followed by the remaining Console Data
safety/content/audience/listing decisions and owner agreement acceptance. No Play
entry, terms acceptance, production key or upload was performed by this audit.
