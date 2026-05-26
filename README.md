# QuillLook

QuillLook is a small macOS Quick Look extension for previewing Markdown files in Finder.

It renders Markdown locally with support for code highlighting, Mermaid diagrams, KaTeX math, tables, task lists, MDX files, and relative local images. The app stays intentionally quiet: open it once to install the extension, then use Space in Finder on `.md`, `.markdown`, `.mdown`, `.mkd`, `.mkdn`, or `.mdx` files.

## Build

```bash
./script/build_and_run.sh --verify
```

This generates the Xcode project with XcodeGen, builds the app, installs it into `~/Applications`, refreshes Quick Look, and launches the containing app.

## Install

Download the latest `QuillLook-0.1.0-macOS.dmg` from the GitHub release, open it, and drag `QuillLook.app` into Applications. Open QuillLook once so macOS can discover the Quick Look extension. If macOS asks, enable the extension in System Settings.

## Public DMG Package

```bash
./script/package_dmg.sh
```

The public package is written to `dist/QuillLook-0.1.0-macOS.dmg`.

Public GitHub downloads require a Developer ID Application certificate and Apple notarization credentials. The script auto-detects a `Developer ID Application` identity, or you can set `QUILLLOOK_DEVELOPER_ID`.

Create the default notary profile once with:

```bash
xcrun notarytool store-credentials quilllook-notary \
  --apple-id YOUR_APPLE_ID \
  --team-id YOUR_TEAM_ID \
  --password YOUR_APP_SPECIFIC_PASSWORD
```

After the DMG is created, publish it to the GitHub release with:

```bash
./script/publish_release.sh
```

## Local Test Package

```bash
./script/package_release.sh
```

The local test package is written to `dist/QuillLook-0.1.0-macOS.zip` and is ad-hoc signed for development only. Use the DMG flow for public downloads.

## Clean Old Registrations

```bash
./script/build_and_run.sh --clean-stale
```

This removes stale QuillLook and legacy MarkdownQL build products, unregisters old Quick Look extensions, and refreshes Quick Look caches.
