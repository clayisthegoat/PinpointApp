#!/usr/bin/env bash
set -euo pipefail
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
# iOS applies its own corner mask. Keep the artwork identical inside it.
sed 's/ rx="220"//' branding/pinpoint.svg > "$tmp/icon.svg"
rsvg-convert -w 1024 -h 1024 "$tmp/icon.svg" -o "$tmp/icon.png"
for entry in 20x20:20 20x20@2x:40 20x20@3x:60 29x29:29 29x29@2x:58 29x29@3x:87 40x40:40 40x40@2x:80 40x40@3x:120 60x60@2x:120 60x60@3x:180 76x76:76 76x76@2x:152 83.5x83.5@2x:167; do
  name="${entry%:*}"
  size="${entry#*:}"
  sips -z "$size" "$size" "$tmp/icon.png" --out "Waypoint/AppIcons/AppIcon${name}.png" >/dev/null
done
cp "$tmp/icon.png" Waypoint/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
