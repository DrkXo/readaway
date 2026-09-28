# Third-Party Notices

Readaway is licensed under the [GNU General Public License v3.0](LICENSE). That license
requires redistributed works to carry their own notices, so this file records the
third-party material that ships inside Readaway's release binaries or is vendored into
this repository.

**What is *not* in this file.** The Dart and Flutter dependency tree is not duplicated
here — it is resolved and versioned in [`pubspec.lock`](pubspec.lock), and the manifests
are listed in the *Built with* section of the [README](README.md#acknowledgments). The
bundled font families are listed at the end, because they already carry their license
texts alongside the font files and need no further action.

## Bundled color themes

The 15 built-in light/dark color schemes are VS Code color themes copied verbatim into
[`packages/readaway_core/lib/src/theme/builtin_vscode_themes.dart`](packages/readaway_core/lib/src/theme/builtin_vscode_themes.dart)
as JSON string literals, and parsed at runtime by
[`packages/vscode_theme_parser`](packages/vscode_theme_parser).

The copies are unmodified: each vendored file is byte-identical to the upstream file
listed below.

| Family   | Upstream                                                                                                                                                                                 | License      | Schemes                                                                                                                                                                                    |
| :------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :----------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: |
| Token    | [ThorstenRhau/token](https://github.com/ThorstenRhau/token) — `contrib/vscode/themes/`                                                                                                   | BSD-3-Clause | `tokenDark`, `tokenLight`, `tokenFlintDark`, `tokenFlintLight`, `tokenMeridianDark`, `tokenMeridianLight`, `tokenTemperDark`, `tokenTemperLight`, `tokenUltraDark`, `tokenUltraLight` (10) |
| Kanagawa | [metapho-re/kanagawa-vscode-theme](https://github.com/metapho-re/kanagawa-vscode-theme) — `themes/`, a VS Code port of [rebelot/kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim) | MIT          | `kanagawaWave`, `kanagawaDragon`, `kanagawaLotus` (3)                                                                                                                                      |
| Flexoki  | [kepano/flexoki](https://github.com/kepano/flexoki) — `vscode/`                                                                                                                          | MIT          | `flexokiDark`, `flexokiLight` (2)                                                                                                                                                          |

All three licenses are GPL-3.0 compatible, so vendoring them in a GPL-3.0 project is
permitted, and Readaway adds no restrictions of its own.

Kanagawa is credited twice on purpose: the JSON in this repository comes from the
`metapho-re` VS Code port, and that port derives from the `rebelot/kanagawa.nvim`
colorscheme, whose palette is in turn inspired by Hokusai's *The Great Wave off Kanagawa*.

### Token — BSD 3-Clause License

Copyright (c) 2026, Thorsten Rhau

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

### Kanagawa — MIT License

The themes in `builtin_vscode_themes.dart` originate from
[metapho-re/kanagawa-vscode-theme](https://github.com/metapho-re/kanagawa-vscode-theme):

```
MIT License

Copyright (c) 2025 Pierre-Alain Castella

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

Which is a port of [rebelot/kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim):

```
MIT License

Copyright (c) 2021 Tommaso Laurenzi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Flexoki — MIT License

Copyright (c) 2023 Steph Ango

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Bundled iconography

Readaway's interface icons come from [Lucide](https://lucide.dev) via the
[`lucide_icons_flutter`](https://pub.dev/packages/lucide_icons_flutter) package, which
compiles Lucide's icon data into Dart source. Readaway references 108 distinct icons, and
Lucide carries a **split license**: the Lucide-original icons are ISC, while the icons
Lucide inherited from the [Feather](https://feathericons.com) project are MIT, © 2013
Cole Bemis. Both are GPL-3.0 compatible, and both license texts are reproduced below, so
whichever icon a given screen uses is covered.

30 of the 108 icons in use are Feather-derived — `alertCircle`, `alertTriangle`,
`arrowLeft`, `arrowRight`, `arrowUpCircle`, `arrowUpRight`, `check`, `chevronDown`,
`chevronLeft`, `chevronRight`, `chevronUp`, `chevronsLeft`, `chevronsRight`, `circle`,
`clock`, `database`, `download`, `info`, `lock`, `minus`, `moon`, `pauseCircle`,
`percent`, `plus`, `power`, `search`, `square`, `trash2`, `type`, `x`. The other 78 are
ISC-licensed Lucide originals. Lucide ships the authoritative per-icon list in its
`LICENSE` file; consult it if you need to settle a specific icon.

### Lucide — ISC License

Copyright (c) 2026 Lucide Icons and Contributors

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

### Feather-derived icons — MIT License

Copyright (c) 2013-present Cole Bemis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Native libraries in the release binaries

The release builds carry prebuilt native shared libraries, pulled in as transitive
dependencies. These are listed here because they are *redistributed inside the shipped
binaries*, not merely linked at build time.

| Library                                       | Source                                                                       | License                              | Where it ships    |
| :-------------------------------------------: | :--------------------------------------------------------------------------: | :----------------------------------: | :---------------: |
| `libmpv.so`                                   | [mpv](https://github.com/mpv-player/mpv), via `media_kit_libs_android_audio` | GPL-2.0-or-later / LGPL-2.1-or-later | Android APKs only |
| `libonnxruntime.so`                           | [ONNX Runtime](https://github.com/microsoft/onnxruntime)                     | MIT                                  | Android and Linux |
| `libsherpa-onnx-*.so`                         | [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx)                         | Apache-2.0                           | Android and Linux |
| `libpdfium.so`                                | [PDFium](https://github.com/pdfium/pdfium), via `pdfrx`                      | BSD-3-Clause                         | Android and Linux |
| `libmediakitandroidhelper.so`                 | [media_kit](https://github.com/media-kit/media-kit)                          | MIT                                  | Android           |
| `libapp.so`, `libflutter.so`, `libdartjni.so` | [Flutter](https://github.com/flutter/flutter)                                | BSD-3-Clause                         | Android and Linux |

All of these are GPL-3.0 compatible. Where a component is GPL-2.0-or-later, the whole
combined work is likewise distributable under GPL-3.0 terms.

### mpv

mpv is dual-licensed by its authors: GNU GPL version 2 or later by default, or GNU LGPL
version 2.1 or later if built without the features that prevent it. The prebuilt
`libmpv.so` shipped by `media_kit_libs_android_audio` is stripped and carries no embedded
license marker, so **which of the two variants it was built as could not be determined
from the binary.** It is recorded here under the more restrictive of the two —
GPL-2.0-or-later — because that is the safe assumption. Upstream license texts:
[GPLv2](https://github.com/mpv-player/mpv/blob/master/LICENSE.GPL) and
[LGPLv2.1](https://github.com/mpv-player/mpv/blob/master/LICENSE.LGPL); the explanation
of when LGPL applies is in mpv's
[`Copyright`](https://github.com/mpv-player/mpv/blob/master/Copyright) file.

Note that mpv is **not** bundled into the Linux artifacts. `media_kit_libs_linux` ships
only a CMake plugin and headers, and the Linux build links against the `libmpv` present
on the build and host system — which is why the release workflow installs `libmpv-dev`
and `mpv` before building. Distributors packaging the Linux AppImage should keep doing
the same.

### ONNX Runtime — MIT License

Copyright (c) Microsoft Corporation

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

### Remaining components

The following are redistributed unmodified, and their full license texts are published
at the canonical sources linked in the table above rather than duplicated here:

- **sherpa-onnx** — Apache License 2.0, <https://www.apache.org/licenses/LICENSE-2.0>,
  also in the upstream repository as `LICENSE`.
- **PDFium** — BSD-3-Clause; the exact copyright notice is in the upstream
  [`LICENSE`](https://github.com/pdfium/pdfium/blob/main/LICENSE) and should be copied
  verbatim into any redistribution.
- **media_kit** — MIT, Copyright © 2021 & onwards, Hitesh Kumar Saini; see the upstream
  [`LICENSE`](https://github.com/media-kit/media-kit/blob/main/LICENSE).
- **Dart and Flutter engines** — BSD-3-Clause; see the Flutter SDK
  [`LICENSE`](https://github.com/flutter/flutter/blob/master/LICENSE) file.

If you repackage Readaway and want a fully self-contained notice bundle, copy the
license files from those repositories alongside this one.

## Fonts

Four font families are bundled under
[`apps/readaway/assets/google_fonts/`](apps/readaway/assets/google_fonts) — Noto Serif,
Noto Sans, JetBrains Mono, and Fira Code — each under the SIL Open Font License 1.1.
Their full license texts are already committed next to the font files as
`OFL-NotoSerif.txt`, `OFL-NotoSans.txt`, `OFL-JetBrainsMono.txt`, and `OFL-FiraCode.txt`,
which satisfies the OFL's requirement to include the license with the font software.
No action is needed beyond keeping those files in place when redistributing.

## For packagers and redistributors

Two obligations in this file are easy to miss:

1. **Ship this file with the binary.** BSD-3-Clause (Token, PDFium) requires its notice
   in the documentation or other materials provided with a binary distribution, and the
   ISC and MIT licenses carry the same requirement in weaker form. An AppImage, tarball,
   store listing, or mirror should all include this file.
2. **Do not use the names of the theme or icon authors to endorse a derivative.** The
   BSD-3-Clause clause 3 and the standard MIT warranty clause both prohibit implying
   endorsement without permission.

Also worth knowing when packaging the Linux AppImage: it expects GTK 3 and mpv to be
present on the target system rather than shipping them, so a `bundle everything` repackage
will change what the binary needs at runtime.

## Updating this file

If a theme, icon set, or native dependency is added, replaced, or removed, update this
file in the same commit. When vendoring a new theme, record where it came from before
editing it, and keep the upstream filename in a `///` comment above the constant — the
existing constants already follow that convention, which is what makes the provenance
auditable:

```dart
  /// token-dark-color-theme.json
  static final VsCodeTheme tokenDark = VsCodeTheme.parse(
    r'''{ ... }''',
  );
```

Provenance can then be re-checked by diffing each vendored literal against its upstream
file, and the native library list by inspecting what the Gradle build merges into the APK
(`build/app/intermediates/merged_native_libs/`) and what the Linux bundle carries
(`build/linux/<arch>/release/bundle/lib/`).
