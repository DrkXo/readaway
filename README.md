<div align="center">
  <img src="docs/assets/logo/foreground.png" alt="Readaway Logo" width="160" />

# Readaway

**Ebook reader with on-device text-to-speech.**

[![Latest release](https://img.shields.io/github/v/release/DrkXo/readaway?display_name=tag&sort=semver)](https://github.com/DrkXo/readaway/releases/latest)
[![License](https://img.shields.io/github/license/DrkXo/readaway)](LICENSE)
[![Platforms](https://img.shields.io/badge/platform-Android%20%7C%20Linux-informational)](https://github.com/DrkXo/readaway/releases)

</div>

---

## Name Inspiration

The name **Readaway** is inspired by Bob Acri's _Sleep Away_
([listen](https://music.youtube.com/watch?v=lHjXY6EuCc4)).

## Features

_Features are on the way._

## Screenshots

<!-- Paste captures here, e.g.:
<img src="docs/assets/screenshots/library.png" alt="Library" width="320" />
<img src="docs/assets/screenshots/reader.png" alt="Reader" width="320" />
Drop them in docs/assets/screenshots/. Captures are very welcome in PRs. -->

_Screenshots are on the way._

## Download

Grab a build from the [latest release](https://github.com/DrkXo/readaway/releases/latest).

| Platform | File                                                           |
| :------- | :------------------------------------------------------------- |
| Linux    | `.AppImage` — run it, or `chmod +x` then double-click          |
| Linux    | `.tar.gz` portable, or `.deb` / `.rpm` to install              |
| Android  | `.apk` — use `arm64-v8a` on most phones, `universal` if unsure |

`sha256sum -c checksums.txt` verifies a download.

On Linux, `./readaway-*.AppImage --install` registers the app for `.epub`,
`.pdf`, and comic archives, so files open from your file manager.

Pre-releases are tagged `-alpha`, `-beta`, `-rc`, `-dev`, or `-preview` and are
listed [separately](https://github.com/DrkXo/readaway/releases). They are not
covered by the stability promise of a stable tag.

## Build from source

Requires the Flutter version pinned in [`.fvmrc`](.fvmrc). [FVM](https://fvm.app) is the path of least resistance:

```bash
git clone https://github.com/DrkXo/readaway.git
cd readaway

fvm install
fvm use
dart pub global activate melos

melos bootstrap      # resolve deps for every package in the workspace
melos run codegen    # freezed / json_serializable / injectable / hive generators
fvm exec flutter run # from apps/readaway
```

### The `hyper_render` fork

`hyper_render`, `hyper_render_core`, and `hyper_render_devtools` are resolved as
git dependencies on [DrkXo/hyper_render](https://github.com/DrkXo/hyper_render)
branch `fix/get-boxes-for-char-range`, declared in `dependency_overrides` in the
root [`pubspec.yaml`](pubspec.yaml). The fork is based on the published
`hyper_render` package and adds `RenderHyperBox.debugLineFragments()`, which
reports the per-line fragments the renderer actually positioned — the basis for
TTS highlighting of wrapped text.

Because it is a git dependency, `melos bootstrap` (or `fvm flutter pub get`)
fetches and caches it automatically — there is nothing extra to clone.

Two things to know:

- Melos does not manage it. It has no directory in this tree and is deliberately
  absent from the pub `workspace:` list in the root `pubspec.yaml`, so
  `melos version` never bumps it and `melos publish` never tries to release the
  fork. To run its tests, clone the fork separately:
  `git clone https://github.com/DrkXo/hyper_render && cd hyper_render && fvm flutter test`.
- The `ref` is pinned to a commit SHA (`aded2c5`), not a branch, so `pub get`
  resolves the same code every time. To pick up new fork commits, push to
  [DrkXo/hyper_render](https://github.com/DrkXo/hyper_render) and bump `ref:`
  in [`pubspec.yaml`](pubspec.yaml).

## Contributing

Bug reports, format requests, and pull requests are all welcome. If you'd like to
contribute code:

1. Fork and branch from `main`.
2. Run `melos bootstrap && melos run codegen` so generated sources are in sync.
3. Keep `melos run analyze` and `melos run format` clean, and add tests where a
   `test/` directory already exists.
4. Use [Conventional Commits](https://www.conventionalcommits.org).

## Special Mention

A nod to _Reverend Insanity_ (蛊真人) by **Gu Zhen Ren**.

Readaway is an independent project with no affiliation to or endorsement by the
artists or creators behind the works it draws on.

## Acknowledgments

**People** — thank you to everyone who has tried Readaway, filed an issue, reported a
bug, tested a pre-release build, or sent a patch.

**Built with** — Readaway stands on a great deal of other people's work. Rather than
list packages here and let it drift out of date, let's point at the manifests:

- [`apps/readaway/pubspec.yaml`](apps/readaway/pubspec.yaml) — app dependencies
- [`packages/readaway_core/pubspec.yaml`](packages/readaway_core/pubspec.yaml) — document engine dependencies
- [`packages/vscode_theme_parser/pubspec.yaml`](packages/vscode_theme_parser/pubspec.yaml) — theme parser dependencies
- [`pubspec.lock`](pubspec.lock) — the exact resolved version of every dependency in every release

And the pieces that live outside the package manager:

| Resource                                                                                                                                                                                                                    | Used for                                                                                                                               |
| :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------- |
| [Flutter](https://flutter.dev) / [Dart](https://dart.dev), pinned via [`.fvmrc`](.fvmrc)                                                                                                                                    | App framework and language                                                                                                             |
| [Melos](https://melos.dev) / [FVM](https://fvm.app)                                                                                                                                                                         | Monorepo scripts, versioning, and SDK pinning                                                                                          |
| [Gradle](https://gradle.org) / [Temurin JDK](https://adoptium.net)                                                                                                                                                          | Android build toolchain                                                                                                                |
| [appimagetool](https://github.com/AppImage/AppImageKit)                                                                                                                                                                     | Linux AppImage packaging, fetched by `scripts/package_linux.sh`                                                                        |
| [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) voice models                                                                                                                                                           | On-device TTS, downloaded on demand from the catalog in [`tts_catalog.json`](apps/readaway/assets/tts/tts_catalog.json)                |
| [Noto Serif](https://fonts.google.com/noto/specimen/Noto+Serif) / [Noto Sans](https://fonts.google.com/noto/specimen/Noto+Sans) / [JetBrains Mono](https://www.jetbrains.com/lp/mono/) / [Fira Code](https://fira-code.org) | Bundled typefaces — serif and sans for body text, monospace for code (all OFL-1.1)                                                     |
| [Lucide](https://lucide.dev)                                                                                                                                                                                                | Icon design                                                                                                                            |
| [Token](https://github.com/ThorstenRhau/token) color themes                                                                                                                                                                 | Bundled light/dark schemes — Light, Dark, Flint, Meridian, Temper, Ultra (BSD-3-Clause)                                                |
| [Kanagawa](https://github.com/rebelot/kanagawa.nvim) color themes                                                                                                                                                           | Bundled light/dark schemes — Wave, Dragon, Lotus (MIT)                                                                                 |
| [Flexoki](https://github.com/kepano/flexoki) color themes                                                                                                                                                                   | Bundled light/dark schemes — an inky paper-and-ink palette (MIT)                                                                       |
| [hyper_render](https://github.com/DrkXo/hyper_render)                                                                                                                                                                       | HTML/Markdown renderer, resolved as a git dependency fork of [`brewkits/hyper_render`](https://github.com/brewkits/hyper_render) (MIT) |

Each of these is used under its own license, and every package named in `pubspec.lock`
belongs to its own maintainers.

## License

Readaway is released under the [GNU General Public License v3.0 or later](LICENSE).
It is copyleft: if you distribute a modified build, you must keep it under the
GPL and publish your source.

Third-party notices — covering the bundled color themes, the Lucide and Feather-derived
interface icons, the native libraries shipped inside the release binaries, and the
bundled fonts — are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). **If you
repackage a Readaway build, ship that file with it**: BSD-3-Clause (Token, PDFium) and
ISC (Lucide) both require their notices to travel with a binary distribution.

---
