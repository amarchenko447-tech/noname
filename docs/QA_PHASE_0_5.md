# Phase 0.5 — concise QA report

Environment: Godot 4.6.3.stable.official.7d41c59c4, Linux. Actual visual captures use
temporary Xvfb + Mesa llvmpipe, Compatibility/OpenGL renderer. No runtime dependency
was added to the project. Work stays on `work`; no force push or Phase 1 gameplay.

## Completed
- Original layered garden, rounded textured soil, bushes, flowers, mushrooms, stones,
  path, fences, translated wooden sign, warm light and soft shadows.
- All nine beds select correctly, with immediate ring, 180ms gentle bounce and pulse.
- 48×48 logical center targets; deterministic closest candidate, lower ID for ties.
- 390×844 logical phone reference: 16px body, 14px minor captions, comfortable controls.
- Responsive safe-area margins for HUD and dialogs; informative Guide/Field notes.
- Reduced motion, lightweight grass/flower/butterfly/pollen/sunlight ambience.
- TranslationServer localization: en/ru/pl/es/de/fr/pt_BR, first-run OS mapping,
  English fallback, instant switching and separately persisted preferences.

## Results
| Verification | Result |
| --- | --- |
| Editor import | PASS, exit 0; final log has no ERROR lines |
| Boot → garden runtime, 60 iterations | PASS, exit 0; no engine/script errors |
| Existing Phase 0 suite, updated phone reference/input-coordinate API | PASS, 45 assertions / 0 failures |
| Phase 0.5 suite | PASS, 5,955 assertions / 0 failures |
| Separate process preferences write → read | PASS; Russian + reduced motion restored despite English OS override |
| Catalog/source audit | PASS; 76 keys × 7 complete translations, no missing source key or formatting-placeholder mismatch |
| Captures | PASS; 42 native PNGs: 7 locales × 2 sizes × 3 views |
| Visual inspection | PASS; reviewed all 42 via native-resolution comparison sheets; no clipped text/overlapping controls observed |
| Whitespace check | PASS, git diff --check |

The 0.5 suite includes all imported translation resources, all unique translated
font glyphs, supported/unsupported/regional OS mapping, English-only fallback key,
immediate text change with same scene identity, stable plot IDs/species, unchanged
coin presentation and gameplay-file sentinel; every corner/edge in a 25-point grid
for each 48×48 bed square at both requested dimensions in all seven locales;
button targets and viewport containment; language selection marking; live GUI
clicks, modal input blocking; direct plot touch input at three ambient phases;
180ms bounce endpoint; reduced motion and synthetic safe-area calculations.

No real crop timers, currency transactions or gameplay save exist yet. The model
and sentinel tests establish preference isolation, not certification of future
save/reward logic. Gameplay integrity remains a Phase 1+ test responsibility.

## Exact commands
From `/workspace/noname` in this restricted environment:
```
export XDG_DATA_HOME=/tmp/mutant-garden/data
export XDG_CONFIG_HOME=/tmp/mutant-garden/config
export XDG_CACHE_HOME=/tmp/mutant-garden/cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 60
godot --headless --path . --script res://scripts/tests/phase_zero.gd
godot --headless --path . --script res://scripts/tests/phase_half.gd
godot --headless --path . --script res://scripts/tests/preferences_restart.gd -- write
godot --headless --path . --script res://scripts/tests/preferences_restart.gd -- read
godot --headless --path . --script res://scripts/tests/preferences_restart.gd -- cleanup
DISPLAY=:99 godot --path . --audio-driver Dummy --script res://scripts/tests/capture_review.gd -- /workspace/noname/docs/screenshots/phase_0_5
git diff --check
```
The display command assumes the temporary Xvfb server already running on :99.
A normal desktop display can run it without DISPLAY=:99. No dummy-headless
screenshots are used. The screenshot script sets actual root window sizes and
asserts image dimensions; it freezes animation time at 2.25s. Screenshots have
`.gdignore` coverage so documentation images are not imported into the game.

## Problems found and fixed during work
- Native class name collision in a drawing-module preload: renamed EnvironmentArt.
- Initial container measurements preceded final text wrapping: relayout now follows
  container sorting/resizing without repeatedly invalidating unchanged margins.
- Scenery depth initially fell behind the backdrop: explicit world/HUD/dialog layers.
- Exact touch-edge float precision dropped boundary taps: a tiny numeric tolerance.
- Synthetic button tests initially injected touch presses without the GUI's mouse
  emulation/press-release cycle: corrected to completed GUI clicks; plot touch events
  are still tested directly. Project explicitly enables touch-to-mouse emulation.
- First CSV import referenced not-yet-generated files; generated translations are
  now checked in, subsequent import/runtime/captures are clean.

## Manual review / reproduction
1. F5: inspect nine soil beds and the decorated border, no overlaps with the HUD.
2. Tap all beds and corners; context and ring should update immediately. Next bed cycles.
3. Watch grass/flowers, two butterflies, three pollen motes and restrained sunlight.
4. Gear → Language: try every native-name option. Text and wooden sign update immediately;
   selected language has a checkmark and tint. Close/relaunch to confirm persistence.
5. Toggle reduced motion: no bounce, drifting pollen, moving butterflies, sway or pulse;
   static selection remains. Background/resume and real OS gesture tests remain below.
6. Open Guide/Field notes informational panels, close with button or Escape/back action.

## Remaining device-specific limitations
Android/iOS exports, real notches/home indicators, physical touch/mouse emulation,
OS suspend/resume lifecycle and OS locale APIs were not tested on devices. Safe-area
policy is implemented and tested with synthetic insets; this is not a device claim.
Mid-range Android FPS, memory, battery and cold start have not been measured. Canvas
caching, small animation budgets and no physics particles are implementation choices,
not proof of a frame-rate target. Screen readers/font scaling and native-speaker
translation editing also remain device/editorial checks.

## Review artifacts and gate
[All 42 screenshots](screenshots/phase_0_5/README.md).
Architecture details are in PLAN.md, ART_GUIDE.md and LOCALIZATION.md.
Phase 0.5 is ready for owner visual review. Stop here; Phase 1 requires approval.
