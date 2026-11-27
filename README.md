<div align="center">
<img src="branding/pinpoint.svg" width="140" alt="Pinpoint logo">

# Pinpoint

**Your map. Your coordinates.**

A native iPhone location simulator with saved places, live map search and on-device developer connectivity.

[![Build](https://github.com/clayisthegoat/PinpointApp/actions/workflows/build-ipa.yml/badge.svg?branch=pinpoint-v1)](https://github.com/clayisthegoat/PinpointApp/actions)
![SwiftUI](https://img.shields.io/badge/SwiftUI-native-0284c7)
![License](https://img.shields.io/badge/license-AGPL--3.0-blue)

[Download latest IPA](https://github.com/clayisthegoat/PinpointApp/releases/latest/download/Pinpoint-unsigned.ipa) · [All releases](https://github.com/clayisthegoat/PinpointApp/releases) · [Report an issue](https://github.com/clayisthegoat/PinpointApp/issues)
</div>

## Features

- Search addresses and places, tap the map or drag the pin.
- Save favorite coordinates locally and revisit them.
- Set, move or restore your simulated location.
- Guided Wi-Fi and cellular connectivity.
- Optional background keepalive and connection warnings.

## Installation

1. Download the [latest unsigned IPA](https://github.com/clayisthegoat/PinpointApp/releases/latest/download/Pinpoint-unsigned.ipa). Successful branch builds are automatically published to Releases.
2. Sign/install the IPA using [SideStore](https://sidestore.io/) or another compatible signing method.
3. Enable Developer Mode and install [LocalDevVPN](https://apps.apple.com/app/id6755608044).
4. Import a valid pairing record for your own iPhone. Files import is recommended for privacy.
5. Select a location and follow the in-app setup prompts.

Never upload or share your pairing record. The app uses Apple's developer location simulation; other apps may detect or reject simulated coordinates. Cellular startup requires the guided Airplane Mode procedure.

## Development

The native SwiftUI app uses MapKit and the idevice library. GitHub Actions builds an unsigned IPA using XcodeGen and Xcode. See [build workflow](.github/workflows/build-ipa.yml) and [third-party notices](THIRD_PARTY_NOTICES.md).

## Credits and license

Pinpoint is a modified fork of [Waypoint by raph559](https://github.com/raph559/WaypointApp), with its own branding, saved locations, interface changes and pairing callback. Original authorship and third-party notices are retained. Distributed under [GNU AGPL-3.0](LICENSE), without warranty.
