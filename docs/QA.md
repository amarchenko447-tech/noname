# Phase 0 validation report

Engine: Godot 4.6.3.stable.official.7d41c59c4, Linux, headless.

## Exact final commands
Run from repository root:
```
export XDG_DATA_HOME=/tmp/mutant-garden/data
export XDG_CONFIG_HOME=/tmp/mutant-garden/config
export XDG_CACHE_HOME=/tmp/mutant-garden/cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 20
godot --headless --path . --script res://scripts/tests/phase_zero.gd
git diff --check
```

Results: editor import PASS (exit 0), boot/runtime smoke PASS (exit 0), automated harness PASS (45 assertions, 0 failures, exit 0), whitespace check PASS.

Harness covers actual boot transition, nine unique initially empty models, all nine plot hit centers and outside rejection, signal-driven context, real mouse/touch input through UI, and HUD/world/card bounds at 720×1280, 1080×1920, 1170×2532, 1440×3200, 1080×2106.

## Issues found and corrected
Initial invocation without XDG overrides could not create Godot user/editor/cache directories under the restricted home and runtime aborted with signal 11. Writable task-local XDG directories resolved it; no engine/source patch required. First harness run caught an inferred type parse error, corrected with explicit Rect2. Root Control changed to ignore mouse so world input can pass through; real input assertions verify this.

## Not run / open acceptance
- Graphical visual review: NOT RUN (no graphical display/Xvfb available).
- Android/iOS export, install, physical touch, notches, OS suspend: NOT RUN.
- Performance, FPS, cold start, memory, screen reader and contrast-tool audit: NOT RUN.
- Gameplay/save/economy/tutorial/mutations/audio/reduced motion: outside Phase 0, not implemented or claimed tested.
- Mobile safe area logic exists but requires actual-device validation.

## Manual review steps
1. Import project.godot in Godot 4.6.3 and press F5. Verify immediate garden with no debugger errors.
2. Check title, cream HUD and layered green island with nine soil diamonds. Check font rendering and background at varied aspect ratios.
3. Tap/click each bed. Selection outline and numbered empty-bed context must update; tapping grass must do nothing.
4. Resize portrait window to each tested aspect ratio; ensure island/title/context/navigation do not overlap or clip.
5. Confirm Shop/Journal are explicitly future labels and no fake gameplay actions exist.
6. Review on a mobile export/device in a later phase before accepting safe-area/performance claims.

## Changed-file groups
project.godot and .gitignore; README; boot/garden scenes; UI/world/strings scripts; minimal plot model; phase-zero harness; original-vector art guide, detailed plan, archived full spec, this QA report; bundled Open Sans regular and attribution; reserved architecture directories.

## Gate / next step
Automated Phase 0 foundation checks pass. Human visual review is pending. Stop here for owner review; Phase 1 vertical slice requires approval.
