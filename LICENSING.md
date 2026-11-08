# Licensing

## QShopper

Copyright (C) 2014-2026 Samuel Nevala.

Unless a file identifies different terms or is third-party material described
below, QShopper project code, tooling and documentation are available under the
GNU General Public License, **version 3 or, at your option, any later version**
(`GPL-3.0-or-later`). The full license is in [LICENSE](LICENSE), and the project's
grant and warranty notice are in [COPYRIGHT](COPYRIGHT).

The Qt 6 license choice does not revoke permissions already granted for earlier
versions. The archived `qt5/qshopper` tree retains its original LGPLv3 license.

## Dependencies and artwork

| Material | Terms and records |
| --- | --- |
| Qt runtime libraries | Qt and bundled third-party licenses, selected for the actual platform payload. Complete offline notices are in [app/licenses](app/licenses/README.md) |
| Qt Virtual Keyboard | Commercial or GPLv3; used by the optional desktop development keyboard, not the Android build. See [Qt's module documentation](https://doc.qt.io/qt-6/qtvirtualkeyboard-index.html#licenses-and-attributions) |
| Font Awesome Free Solid 7.3.1 font | SIL Open Font License 1.1. Unmodified desktop OTF; full notice in [FontAwesome.txt](app/licenses/FontAwesome.txt) |
| Font Awesome brand SVG | CC BY 4.0, with fill changed to blue. Attribution and full license in [FontAwesome.txt](app/licenses/FontAwesome.txt); source/hash in [logos/sources.json](app/logos/sources.json) |
| Qt logo | Upstream Qt asset and trademark; source/hash in [logos/sources.json](app/logos/sources.json). The project license does not grant rights to Qt's trademarks |
| Background illustrations | Generated for QShopper. Prompts, revisions, inventories and exports are documented in [artwork/UI-013](artwork/UI-013/README.md) |

Third-party copyrights, license notices and trademark rights remain with their
owners. The project's GPL grant does not replace those terms. Old assets in Git
history are not the current background set and do not acquire new permissions
from this license selection.

## Distributing builds

Preserve the applicable notices and include the project license with a build.
Provide the corresponding source and build/install information required by the
app's GPL and the licenses of its actual dependencies. A GitHub source checkout
and in-app notice reader are useful parts of that work; they do not, by
themselves, complete every binary-distribution obligation.

Record the exact source revision, Qt kit and packaged dependencies for each
released build. Qt's [open-source obligations](https://www.qt.io/development/open-source-lgpl-obligations)
and the full license texts are the references. Final binary/source delivery,
installation arrangements, release signing and store submission remain part of
[REL-001](tickets/REL-001.json).
