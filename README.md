# Mutant Garden
Original offline mobile gardening game using **Godot 4.6.3 stable / GDScript**.
Current milestone: **night sprint — expandable world + planting, growth and harvest**.

Open `project.godot` in Godot 4.6.3 and press **F5**. A new game starts with 150 coins.
Tap an empty bed, choose a seed and confirm its price. Sunny Carrot matures in
30 seconds; tap the mature plant or Harvest to receive coins and free the bed.
Growth continues while the game is closed. Coins and crop removal save together.

Drag the map with one finger/mouse; pinch or use the mouse wheel to zoom.
Garden recenters the camera. Gear opens seven-language settings and Reduced Motion.
The HUD stays fixed while the world moves. Nine beds form a starter region;
world data and gameplay use stable IDs and support more objects.

## Implemented
- Six original plant silhouettes, four visual stages each, resource-based balance.
- Seed cards, localized prices/timers, insufficient-funds feedback, immediate language changes.
- Planting/growth/maturity/harvest Tweens, gentle species-specific idle movement,
  soil/light particles and coins flying to the balance; Reduced Motion support.
- UTC/offline growth with one shared clock, atomic versioned snapshots,
  migration from the Phase 0.75 world save, backup recovery and stale-action guards.
- Original cozy meadow, dimensional beds, ambience, safe-area portrait layout.
- English, Русский, Polski, Español, Deutsch, Français, Português (Brasil).

[Russian sprint report](docs/NIGHT_SPRINT_REPORT.md) ·
[Actual gameplay screenshots](docs/screenshots/night_sprint/README.md) ·
[World architecture](docs/WORLD_EXPANSION_PLAN.md) ·
[Save format](docs/SAVE_FORMAT.md) · [Balance](docs/BALANCE.md) ·
[Localization](docs/LOCALIZATION.md) · [Art](docs/ART_GUIDE.md).
Historical foundation evidence: [Phase 0.5](docs/QA_PHASE_0_5.md),
[Phase 0.75](docs/QA_PHASE_0_75.md).

## Checks
```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 120
godot --headless --path . --script res://scripts/tests/phase_zero.gd
godot --headless --path . --script res://scripts/tests/phase_half.gd
godot --headless --path . --script res://scripts/tests/phase_three_quarters.gd
godot --headless --path . --script res://scripts/tests/gameplay.gd
godot --headless --path . --script res://scripts/tests/gameplay_ui.gd
```
Separate-process persistence checks and isolated clock details are in the report.
In restricted environments set XDG_DATA_HOME, XDG_CONFIG_HOME and XDG_CACHE_HOME
to writable task-local directories. Automated fixtures use separate save files.

## Render actual screenshots
With a graphical display (or Xvfb):
```sh
godot --path . --audio-driver Dummy --script res://scripts/tests/capture_gameplay.gd -- /absolute/output
godot --path . --audio-driver Dummy --script res://scripts/tests/capture_plant_study.gd -- /absolute/output/plant-study.png
```
The first command captures garden/seed panels in seven languages at 390×844 and
430×932. It earns and spends coins through real gameplay commands in an isolated
save and advances an injected clock to show all stages. Static captures freeze
ambience at 2.25 seconds. They are real viewport PNGs, not mockups. Screenshot
fixtures are not the default new-game state. Open Settings in the running game
for language and motion controls; capture_review.gd captures those dialogs too.

No third-party runtime packages, network calls, analytics or game SDKs are used.
No physical Android/iOS benchmark or export is claimed. Large-world streaming,
buildings, biomes and mutation gameplay remain future work. Level 1 is a static
foundation label; the HUD harvest count is real. Source/art license remains
pending the owner's decision; third-party font notices are bundled.

## Technical stabilization / mobile acceptance
[Audit and measured results](docs/qa/REPORT.md) ·
[Physical-device checklist and build instructions](docs/qa/MOBILE_ACCEPTANCE.md) ·
[Updated real screenshots](docs/qa/screenshots/README.md).

Run stabilization.gd and mobile_layout.gd with the same --headless test command
as above. `python tests/run_crash_recovery.py` kills real isolated Godot processes
to test durable commands and interrupted writes. performance_audit.gd and
soak_audit.gd require a graphical display; exact commands and measurement limits
are in the report. Export presets exclude tests/reports and include font notices.
Android/iOS native acceptance is pending physical devices and complete toolchains.
