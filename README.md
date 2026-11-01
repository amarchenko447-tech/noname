# Mutant Garden
Original offline mobile gardening game using **Godot 4.6.3 stable / GDScript**.
Current milestone: **Phase 0.75 — expandable world architecture**.
Phase 1 gameplay has not started.

Open `project.godot` in Godot 4.6.3 and press **F5**.
Tap any bed, drag the map, pinch to zoom (desktop: mouse drag/wheel),
use Garden to recenter, or open the gear button → Language.
Guide and Field notes open informative panels; planting, growth, rewards and shop
transactions belong to the next phases. Level 1, 150 coins and 0/24 discoveries are
foundation presentation values, not a new progression system.

## This milestone
- Original layered meadow, fences, wooden sign, bushes, mushrooms, flowers and pebbles.
- Rounded dimensional soil beds, 180ms selection bounce and restrained glow.
- Lightweight swaying grass, pollen, butterflies and sunlight; reduced-motion mode.
- Readable 390×844 logical reference, independently scaled artwork, safe-area margins.
- Full 48×48 logical bed targets, nearest-center selection and stable ID tie-break.
- English, Русский, Polski, Español, Deutsch, Français, Português (Brasil).
- Immediate language changes using Godot TranslationServer, OS detection on first run,
  English fallback, separately persisted preferences. No network or account required.

[QA report](docs/QA_PHASE_0_5.md) · [Screenshot gallery](docs/screenshots/phase_0_5/README.md)
· [Architecture/plan](docs/PLAN.md) · [Localization guide](docs/LOCALIZATION.md)
· [Art guide](docs/ART_GUIDE.md) · [Asset notices](assets/LICENSES.md).

## Automated checks
```
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 60
godot --headless --path . --script res://scripts/tests/phase_zero.gd
godot --headless --path . --script res://scripts/tests/phase_half.gd
godot --headless --path . --script res://scripts/tests/preferences_restart.gd -- write
godot --headless --path . --script res://scripts/tests/preferences_restart.gd -- read
godot --headless --path . --script res://scripts/tests/preferences_restart.gd -- cleanup
```
The restart test requires separate invocations, in order. Test preferences use their
own files. In restricted environments, set XDG_DATA_HOME, XDG_CONFIG_HOME and
XDG_CACHE_HOME to writable task-local directories first; see the QA report.

## Actual screenshots
With a graphical display (or Xvfb):
```
godot --path . --audio-driver Dummy --script res://scripts/tests/capture_review.gd -- /absolute/output
```
This runs the real boot/garden and captures all seven languages at 390×844 and
430×932, including Settings and Language dialogs. Animation time is frozen at
2.25 seconds for repeatability. The PNGs are native viewport captures, not mockups.
For an exact desktop window, set the project's Window Width/Height Override to
390/844 or 430/932; startup overrides can supersede CLI --resolution.

No third-party runtime packages, network calls, analytics or game SDKs are used.
No Android/iOS export or device benchmark is claimed. Source/art license remains
pending the owner's decision; third-party font notices are bundled.

## World expansion proposal — Phase 1 paused
The long-term game is an expandable isometric farm; nine beds are the starter area.
[Technical plan and audit](docs/WORLD_EXPANSION_PLAN.md) describes the proposed
prerequisite refactoring. The core architecture is implemented in Phase 0.75; see docs/QA_PHASE_0_75.md.
