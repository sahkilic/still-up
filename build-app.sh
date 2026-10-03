#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
cd "$root"

swift build -c release

app="$root/dist/Still Up.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources/Fonts"

cp ".build/release/still-up" "$app/Contents/MacOS/still-up"
cp "Support/Info.plist" "$app/Contents/Info.plist"
cp Sources/StillUp/Fonts/*.ttf "$app/Contents/Resources/Fonts/"
cp Sources/StillUp/Fonts/OFL.txt "$app/Contents/Resources/Fonts/"
cp "Support/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"

bundle="$(find .build/release -name '*StillUp.bundle' -print -quit || true)"
if [ -n "$bundle" ]; then
  cp -R "$bundle" "$app/Contents/Resources/"
fi

codesign --force --sign - "$app" >/dev/null
echo "$app"
du -sh "$app"
