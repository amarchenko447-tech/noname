# Mutant Garden — implementation plan

## Repository audit
The supplied specification was read in full; archived at `docs/SPEC.md`.
Repository: `/workspace/noname`, branch `work`, initially no commits or source files.
Remote: `https://github.com/amarchenko447-tech/noname.git`. No remote changes or push performed.
Available engine: Godot 4.6.3 stable, official Linux build. No existing engine constraint.
No AGENTS.md files found under /workspace. No package dependencies required.

## Phase 0 scope and architecture
- `project.godot`: portrait 1080×1920 reference, expanding canvas, Compatibility renderer.
- `scenes/boot/boot.tscn`: local boot immediately transitions to garden without fake loading.
- `scenes/garden/garden.tscn`: Control-based HUD composed by `scripts/ui/garden.gd`.
- `scripts/ui/garden_world.gd`: Node2D rendering original layered vector island and nine beds; exact diamond hit testing, mouse and touch, signal-driven selection. Render order follows depth.
- `scripts/models/plot_data.gd`: typed minimal plot identity/species model, independent of UI.
- `scripts/ui/strings.gd`: centralized product copy; dynamic labels compose values.
- Cream HUD, original pastel island, furrowed soil, tiny daisies and stones; bundled licensed font.
- Safe-area insets on mobile, minimum 24 design pixels, expanding layout and reserved world zone.
- Foundation shows starting balance and empty collection as presentation values. No economy yet.
- Shop/journal are visibly marked SOON as labels, not nonfunctional buttons.
- Planned directories are reserved with .gitkeep; no empty pretend service implementations.

## Next phases — require approval after Phase 0
1. Vertical slice: introduce GameState, TimeService, SaveManager autoloads; one Daisy planting/water/growth/harvest transaction; seed inventory, sell/keep and journal event. Ten cycles plus restart gate.
2. Gardening: six PlantDefinition Resources and economy resources; all nine beds, seed purchases and thresholds; shared one-second timer. Full basic transaction gate.
3. Mutations/journal: seeded mutually exclusive result persisted before reveal, 24 entries, filtering and dates, deterministic tests. Mutation replay and reload gate.
4. Art/audio: growth-stage assets, variant overlays, bounded tweens, particles, licensed or original audio, AudioManager and decorations. Profile real devices; measure performance.
5. Tutorial/accessibility: SettingsManager, six tutorial steps (spec's "3-step" overview interpreted as the detailed six actions), five-second tutorial override, skip, reset, reduced motion, haptics and settings. Notification permission only with explicit opt-in and actual platform support.
6. Release QA: Android export configuration and device tests, signed export only when signing material/toolchain exists. iOS requires macOS/Xcode. Do not claim store readiness from desktop tests.

## Future service contracts
GameState owns synchronous atomic purchases, planting, watering and reward claims, emits state_changed. UI never mutates currency. SaveManager validates/migrates JSON, writes temp then replaces, keeps last-good backup, reports failures. TimeService combines UTC and foreground monotonic elapsed, injectable clock in tests. SettingsManager owns persisted preferences. AudioManager controls independent master/music/SFX buses. These are added with working functionality, not Phase 0 stubs.

## Validation strategy
Phase 0 executable headless SceneTree harness loads actual boot/garden, checks unique empty plots, hit regions, input dispatch, selection and viewport bounds at five sizes. Editor import validates scripts/resources. Runtime smoke runs boot into garden. Graphical/device checks remain separate and must be reported as not run when unavailable.
Future tests cover time jumps, 48h resume, corruption and backup, 20 repeated claims, save replay, probabilities, nonnegative inventory/currency, thresholds, tutorial skip/completion and settings persistence. Manual QA covers animations, sound, notches and physical touch.

## Major risks and unresolved decisions
- Headless tests cannot certify rendered appearance, actual safe areas, accessibility or mobile performance.
- Finished art/animation/audio production remains substantial; vector placeholders establish the palette only.
- Spec conflicts: nine empty plots at fresh launch versus three planted during tutorial. Fresh state stays empty; tutorial population must be explicitly resolved during Phase 1/5, with scarce resources protected.
- Tutorial describes automatic coin reward while core loop specifies sell-or-keep. Preserve explicit choice, decide tutorial guidance before implementing.
- Offline clock manipulation cannot be prevented without a server; do not punish players.
- Save atomic replacement is platform-dependent and needs device force-close testing.
- No release signing credentials or mobile export/device verification yet.

## Phase 0 review gate
Review foundation and run the manual desktop smoke steps in QA.md. Stop before gameplay, autoload persistence or later content. Headless foundation checks pass; visual/mobile acceptance remains open.

## Phase 0.5 — authorized visual polish and localization addendum
Completed between the Phase 0 review and Phase 1. The latest user requirements
extend the original English-only UI to seven languages. They also authorize a
preferences-only SettingsManager now, rather than deferring all settings to Phase 5.

Architecture remains boot → garden, Node2D world + Control HUD + separate PlotData.
World art is split into cached environment and bed nodes, shared drawing primitives,
a small ambient layer and original icon/backdrop components. Text and controls use
a 390×844 logical reference for real mobile readability; the 1080-unit artwork
scales independently. Stable plot IDs and model semantics are unchanged.

New UX: complete 48×48 logical center squares per plot; nearest-center candidate
resolution with stable ID ties; 180ms bounce/glow; immediate selection; working
Next bed, Guide, Field notes information and gear/settings. No fake planting or
purchasing actions. Level/coins/collection remain foundation presentation values.

Localization: TranslationServer + UTF-8 CSV/generated translations, seven locales,
regional OS mapping with English fallback, immediate rebinding without scene reload,
separate atomic preferences file, font/diacritic and long-layout verification.
See LOCALIZATION.md, ART_GUIDE.md and QA_PHASE_0_5.md for details and evidence.

Phase 0.5 automated checks and desktop screenshot review pass. Physical-device
safe areas, touch emulation/gesture behavior, mobile GPU/battery/performance and
native-speaker editorial review remain explicit limitations. Phase 1 gameplay is
still gated on owner approval after this milestone; no later gate was skipped.

## New world-expansion decision — Phase 1 paused
The owner has redefined the long-term product as an expandable isometric farm.
The nine beds are the starter/tutorial region, not a model or save-size limit.
See `WORLD_EXPANSION_PLAN.md` (Russian) for the audit, grid/object/camera/gesture
proposal, scalable snapshot strategy, rendering approach, risks and prerequisite
refactoring gates. This is a proposal only; implementation awaits plan review.
The unfinished Phase 1 draft was preserved outside the Godot project and the active
source was restored to accepted Phase 0.5. No Phase 1 gameplay is committed or shipped.

## Phase 0.75 completed
The accepted expansion plan is implemented: resource-defined starter region, stable
IDs, occupancy/query model, separate HUD CanvasLayer, bounded Camera2D and gestures,
versioned atomic world snapshot and migration boundary. See QA_PHASE_0_75.md.
The later night-sprint request authorizes proceeding to planting/growing after this
stable milestone; it supersedes the earlier requirement to pause before Phase 1.
