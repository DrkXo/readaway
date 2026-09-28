<div align="center">
  <img src="docs/assets/logo/foreground.png" alt="Readaway Logo" width="160" />

# Readaway

**Ebook reader — built with Flutter.**

[![Latest release](https://img.shields.io/github/v/release/DrkXo/readaway?display_name=tag&sort=semver)](https://github.com/DrkXo/readaway/releases/latest)
[![License](https://img.shields.io/github/license/DrkXo/readaway)](LICENSE)
[![Platforms](https://img.shields.io/badge/platform-Android%20%7C%20Linux-informational)](https://github.com/DrkXo/readaway/releases)

</div>

---

## Name Inspiration

The name **Readaway** is inspired by Bob Acri's _Sleep Away_
([listen](https://music.youtube.com/watch?v=lHjXY6EuCc4)).

Readaway is an independent project with no affiliation to or endorsement by the artists
or creators behind the works it draws on.

## Features

_Feature's list are on the way._

## Screenshots

<!-- Paste captures here, e.g.:
<img src="docs/assets/screenshots/library.png" alt="Library" width="320" />
<img src="docs/assets/screenshots/reader.png" alt="Reader" width="320" />
Drop them in docs/assets/screenshots/. Captures are very welcome in PRs. -->

_Screenshots are on the way._

## Download

### Stable vs. pre-releases

> **[Download the latest stable release](https://github.com/DrkXo/readaway/releases/latest)**
>
> `/releases/latest` always resolves to the newest **non-prerelease** tag, so this link
> is safe to bookmark and share.

> **[Browse all releases & pre-releases](https://github.com/DrkXo/readaway/releases)**
>
> Use this only if you want early builds. A release is flagged as a pre-release when its
> version contains `-alpha`, `-beta`, `-rc`, `-dev`, or `-preview` — tags look like
> `readaway-v1.3.0-beta.0`. Pre-releases are not covered by the stability promise that
> comes with a stable tag, so back up anything you care about.

## Build from source

Requires the Flutter version pinned in [`.fvmrc`](.fvmrc). [FVM](https://fvm.app) is the path of least resistance:

```bash
fvm install
fvm use
dart pub global activate melos

melos bootstrap      # resolve deps for every package in the workspace
melos run codegen    # freezed / json_serializable / injectable / hive generators
fvm exec flutter run # from apps/readaway
```

Common tasks, all defined as [Melos](https://melos.dev) scripts in `pubspec.yaml`:

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

No affiliation, and no endorsement implied.

## Acknowledgments

**People** — thank you to everyone who has tried Readaway, filed an issue, reported a
bug, tested a pre-release build, or sent a patch.

**Built with** — Readaway stands on a great deal of other people's work. Rather than
list packages here and let it drift out of date, lets point at the manifests:

- [`apps/readaway/pubspec.yaml`](apps/readaway/pubspec.yaml) — app dependencies
- [`packages/readaway_core/pubspec.yaml`](packages/readaway_core/pubspec.yaml) — document engine dependencies
- [`packages/vscode_theme_parser/pubspec.yaml`](packages/vscode_theme_parser/pubspec.yaml) — theme parser dependencies
- [`pubspec.lock`](pubspec.lock) — the exact resolved version of every dependency in every release

And the pieces that live outside the package manager:

|                                                                                                          Resource                                                                                                           |                                                        Used for                                                         |
| :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------------------------: |
|                                                                  [Flutter](https://flutter.dev) / [Dart](https://dart.dev), pinned via [`.fvmrc`](.fvmrc)                                                                   |                                               App framework and language                                                |
|                                                                                     [Melos](https://melos.dev) / [FVM](https://fvm.app)                                                                                     |                                      Monorepo scripts, versioning, and SDK pinning                                      |
|                                                                             [Gradle](https://gradle.org) / [Temurin JDK](https://adoptium.net)                                                                              |                                                 Android build toolchain                                                 |
|                                                                                   [appimagetool](https://github.com/AppImage/AppImageKit)                                                                                   |                             Linux AppImage packaging, fetched by `scripts/package_linux.sh`                             |
|                                                                              [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) voice models                                                                              | On-device TTS, downloaded on demand from the catalog in [`tts_catalog.json`](apps/readaway/assets/tts/tts_catalog.json) |
| [Noto Serif](https://fonts.google.com/noto/specimen/Noto+Serif) / [Noto Sans](https://fonts.google.com/noto/specimen/Noto+Sans) / [JetBrains Mono](https://www.jetbrains.com/lp/mono/) / [Fira Code](https://fira-code.org) |                   Bundled typefaces — serif and sans for body text, monospace for code (all OFL-1.1)                    |
|                                                                                                [Lucide](https://lucide.dev)                                                                                                 |                                                       Icon design                                                       |
|                                                                                 [Token](https://github.com/ThorstenRhau/token) color themes                                                                                 |                 Bundled light/dark schemes — Light, Dark, Flint, Meridian, Temper, Ultra (BSD-3-Clause)                 |
|                                                                              [Kanagawa](https://github.com/rebelot/kanagawa.nvim) color themes                                                                              |                                 Bundled light/dark schemes — Wave, Dragon, Lotus (MIT)                                  |
|                                                                                  [Flexoki](https://github.com/kepano/flexoki) color themes                                                                                  |                            Bundled light/dark schemes — an inky paper-and-ink palette (MIT)                             |

Each of these is used under its own license, and every package named in `pubspec.lock`
belongs to its own maintainers.

## License

Readaway is released under the [GNU General Public License v3.0](LICENSE). It is
copyleft: if you distribute a modified build, you must keep it under the GPL and
publish your source.

Third-party notices — covering the bundled color themes, the Lucide and Feather-derived
interface icons, the native libraries shipped inside the release binaries, and the
bundled fonts — are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). **If you
repackage a Readaway build, ship that file with it**: BSD-3-Clause (Token, PDFium) and
ISC (Lucide) both require their notices to travel with a binary distribution.

---

<div align="center">
  <sub>Made with Flutter, Melos, and a lot of late-night reading.</sub>
</div>
