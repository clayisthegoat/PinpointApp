# Pinpoint changelog

Version-level history, newest first. Retained GitHub release artifacts sometimes include changes developed for the next version; these overlaps are noted. Early prototypes are historical milestones, not published IPA releases. No claim of third-party location-sharing compatibility is made.

## 1.7.2

- Added isolated synthetic event tester with 1, 2, 5 and 10 second intervals, start/stop, event count and last/average interval. Added diagnostics navigation link. No system-wide GPS changes; mock events remain local.

## 1.7.1

- Expanded read-only location diagnostics with observation duration, callback age, error count, start/stop state and coordinate-free share summary. No GPS backend changes.

## 1.7.0

- Added five-shortcut home navigation, map location control, favorite folder assignment, appearance preferences, optional shortcut haptics, JSON backup/import with confirmation, GitHub update checker and health dashboard. Analytics are local counts; notices are current state only. Backups exclude pairing credentials.

## 1.6.0

- Added diagnostic timer Live Activity, Dynamic Island presentation and rectangular Lock Screen launcher widget. Retained home widget. Changed publishing to reuse releases and remove duplicate legacy release entries while preserving tags.

## 1.5.2

- Consolidated network and read-only Core Location diagnostics with the v1.5 dashboard and widget. Added location permission description and cancellation of superseded builds. Some diagnostic code was already present in the retained v1.5 release artifact.

## 1.5.1

- Experimental branch based on v1.4.1, not v1.5. Added ordinary HTTPS reachability check with real-location prerequisite. Does not inherit v1.5 dashboard or widget.

## 1.5.0

- Added route dashboard with target speed, remaining distance, elapsed time and estimated remaining time; active route map overlay, home shortcuts, connection diagnostics and static launcher widget. Retained release source also includes network and Core Location diagnostics.

## 1.4.1

- Walking and driving setup unified; exact preview route reused, preview origin validated, walking speed controls added. These changes were already included in the retained v1.4 release source. Retained v1.4.1 source additionally includes network diagnostics from subsequent development.

## 1.4.0

- Added dedicated drive setup, route preview, speed and variation controls, pause/resume. Retained release source also includes unified walking setup and exact preview route changes.

## 1.3.0

- Added interactive favorite map picker with center pin, pan/zoom and address search; canonical SVG app icon rendering; automatic latest-release publishing.

## 1.2.0

- Versioned redesigned favorite browser with search, guided add/edit and map review. The retained v1.1 release source already includes the browser; actual retained release diff is version and publishing metadata.

## 1.1.0

- Added named favorites, history, map styles, connection dashboard, routed walk/drive controls and timed restore. Retained release also includes dedicated favorites browser and editor.

## 1.0.1

- Fixed pairing callback scheme collision with Waypoint; added Pinpoint branding, icon generation, README and automated IPA publishing.

## 1.0.0

- Initial iOS fork: Pinpoint display name, bundle identifier, blue styling, favorites and location control labels. No retained standalone release.

## 0.4.0

- Pre-release feasibility milestone: on-device developer location testing using existing Waypoint, pairing and local VPN. Not a published Pinpoint IPA.

## 0.3.0

- Windows prototype integrated developer image preparation, tunnel setup and set/clear controls.

## 0.2.0

- Windows prototype added USB device detection.

## 0.1.0

- Initial local Windows map prototype with search, saved places and route preview; no GPS writes.
