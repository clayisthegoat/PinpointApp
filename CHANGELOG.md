# Pinpoint changelog

## 1.9.1

- Differentiated preferences and device setup toolbar icons.
- Redesigned bottom shortcuts as rounded accent-tinted buttons with press animations.
- Applied the selected accent to app presentations, map controls and navigation elements.
- Expanded the appearance palette to 13 presets and added a native custom color picker.
- Preserved existing spoofing logic, saved preferences and locations.

## 1.9.0

- Corrected legacy Waypoint branding in app messages, website and support documentation.

- Added collapsible map controls and named favorite markers with a visibility preference.
- Added editable bottom shortcuts with reordering and reset.
- Added local diagnostic event logs with filtering, sharing and clearing.
- Added device setup progress and clearer onboarding instructions.
- Added bundled in-app changelog.
- Added a spoofing Live Activity with session mode, progress and stale status.
- Refined the existing Home Screen launcher widget; live shared session data is not yet supported.

## 1.8.0

- Removed the bottom More shortcut; preferences remain accessible from the top-left Settings menu.
- Reorganized settings and preferences, including About and update progress.
- Added a dedicated searchable location history screen with individual deletion and clear confirmation.
- Added timestamps to new history entries; existing entries remain compatible.
- Added troubleshooting guidance to technical errors and simulation connection failures.
- Preserved the v1.7.5 route movement implementation.

## 1.7.5

- Improved Start Walk and Start Drive button feedback and error handling.
- Allow movement to initialize from the selected map pin when needed.
- Update route coordinates within the existing simulation session rather than recreating it at every step.
- Report interrupted movement and preserve cellular handoff restrictions.
