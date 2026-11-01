# Mutant Garden
Original offline mobile gardening game. **Phase 0 foundation only.**

Open `project.godot` with Godot **4.6.3 stable** and press F6 on boot, or F5.
CLI: `godot --path .`

The preview contains nine empty isometric garden beds. Click/tap one to inspect it.
Shop and journal are future destinations, visibly labeled SOON. Planting, growth,
saving, audio and game economy begin in later phases after review.

## Checks
```
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 20
godot --headless --path . --script res://scripts/tests/phase_zero.gd
```
In a restricted environment, set XDG_DATA_HOME, XDG_CONFIG_HOME and XDG_CACHE_HOME
to writable task directories first (see docs/QA.md).

See docs/PLAN.md for architecture and phase gates, docs/QA.md for exact results,
and docs/ART_GUIDE.md and assets/LICENSES.md for artwork and font provenance.
No network, external dependencies, SDKs or services are required to run.
No Android/iOS binary has been produced or tested. Source licensing is not yet
selected by the project owner; bundled third-party assets retain their licenses.
