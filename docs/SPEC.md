# MUTANT GARDEN — COMPLETE CODEX IMPLEMENTATION SPECIFICATION
Version 1.0 | Target: mobile portrait | Language: English | Engine: Godot 4.x stable, GDScript

## 0. EXECUTION CONTRACT FOR CODEX
You are the lead Godot game engineer, technical artist, UX engineer and QA engineer. Build an original, runnable, polished offline-first mobile gardening game named **Mutant Garden**. Do not clone Hay Day or copy its art, branding, UI, sound or assets. Follow this specification as the source of truth. Inspect the repository first, identify its existing structure and Godot version, then write a short implementation plan in `docs/PLAN.md`. Commit work in small logical commits. Build one vertical slice before broadening content. Do not claim tests passed unless you actually ran them. If Godot/editor/export tools are unavailable, report exactly what you could not verify. Never embed API secrets. Do not add advertising SDKs, real-money payments, analytics SDKs or external tracking in MVP.

## 1. PRODUCT VISION AND SCOPE
Genre: cozy idle gardening / collection / light economy. Player fantasy: nurture a tiny magical garden, discover surprising plant mutations, fill a collectible botanical journal and decorate an expanding patch of land. Sessions: 2–8 minutes, 2–4 times daily. Tone: gentle, playful, rewarding, never stressful. Audience: English-speaking casual players aged 13+. Initial release: Android-first, iOS-ready; offline single-player, no account required. One-handed portrait touch controls. Not a competitive game. No energy gates, gambling, lootboxes, pay-to-win or forced ads.

**MVP must contain:** 3x3 plots (9 total), six seed species, three mutation families, planting/watering/growing/harvesting, sell-or-keep harvest choice, coins, seed shop, collection journal, three cosmetic decorations, tutorial, persistent local save, settings (music/SFX/haptics), English UI, accessible reduced-motion option, optional notifications only after consent, Android-compatible touch UI. The game must run without network access.

**Out of scope for MVP:** multiplayer, trading, cloud saves, online events, payments, ad networks, subscriptions, live-service backends, real-time chat, user-generated content, procedural AI-generated assets, 3D character locomotion, complicated crafting, leaderboards, social logins.

## 2. TECHNICAL STACK
Godot 4.x stable; GDScript only. Prefer a 2D renderer with hand-authored isometric-looking 2.5D sprites (not full 3D), avoiding expensive 3D assets and keeping mobile performance predictable. Use Control nodes for HUD, Node2D for garden world, AnimatedSprite2D/AnimationPlayer/Tween for effects. Design baseline 1080x1920 portrait, scalable to varied aspect ratios using anchors and safe-area insets; UI must not overlap notches/home indicators. Target 60 FPS on mid-range phones; graceful 30 FPS fallback. Texture atlas where practical, limited particles and overdraw. Use built-in Godot resources and locally stored assets; no proprietary assets without license. Use deterministic data-driven resource definitions for plants and mutations.

Suggested structure:
```
project.godot
assets/{plants,plots,ui,decorations,vfx,audio,fonts}/
scenes/{boot,main_menu,garden,shop,journal,settings,components,overlays}/
scripts/{autoload,models,systems,ui,tests}/
resources/{plants,mutations,economy,decorations}/
docs/{PLAN.md,ART_GUIDE.md,QA.md,BALANCE.md}
tests/
```
Autoloads: GameState (runtime state), SaveManager (save/load), TimeService (UTC clock), AudioManager, SettingsManager. Keep gameplay state separate from UI. Signal-driven UI updates, no polling every frame for timers; use a 1-second shared timer only when garden visible.

## 3. CORE GAME LOOP
1. Player opens garden and sees ready plots and progress.
2. Tap empty plot -> seed picker with owned seeds, costs and growth durations.
3. Select seed -> plant immediately, subtract one seed (seed inventory must never go negative).
4. Water newly planted seed once for a modest speed bonus; subsequent watering optional once per growth cycle, no penalty for ignoring it.
5. Growth continues based on saved UTC timestamps while app is closed.
6. Harvest when timer completes -> 0.5–1.2 s reward animation; discover mutation by seeded RNG at harvest (once per plot per growth cycle).
7. Receive harvest item, choose **Sell** for coins or **Keep** in collection inventory. Journal discovery unlocks automatically on first occurrence even if sold.
8. Spend coins on seeds and decorative upgrades. Return for new discoveries.

Critical rule: timer-based growth and reward generation must be idempotent. Background/resume and repeated tapping must not double-grant harvests. Never punish the player for time away; no crop withering.

## 4. INITIAL CONTENT AND BALANCE (CONFIGURABLE DATA)
Starting balance: 150 coins; starting inventory: 4 Daisy seeds, 3 Carrot seeds, 2 Mint seeds; 9 plots unlocked, 3 planted during tutorial. Define plant data in resources, not hard-coded UI strings.

| Species ID | Display name | Seed price | Growth | Base sell value | Color / silhouette |
|---|---|---:|---:|---:|---|
| daisy | Moon Daisy | 10 coins | 2 min | 18 coins | white flower, blue center |
| carrot | Ember Carrot | 15 | 5 min | 28 | coral root, leafy top |
| mint | Cloud Mint | 20 | 10 min | 38 | pale green clustered leaves |
| tulip | Star Tulip | 35 | 20 min | 65 | lavender star petals |
| berry | Glowberry | 60 | 45 min | 110 | glowing cyan berries |
| orchid | Dream Orchid | 100 | 90 min | 185 | pink/violet layered flower |

Seed unlocks: first three available initially; Tulip after 5 total harvests; Glowberry after 15; Orchid after 35. Each harvest produces one item. These values are tuning placeholders, not real-world financial projections. Always display precise growth times and coin costs before purchase.

Mutation families: **Golden** (warm gold glimmer, +2x sell value), **Giant** (1.35x visual scale, +1.6x sell value), **Prismatic** (cycling pastel iridescence, +3x sell value). Mutations are mutually exclusive per harvested plant. Base probability: Golden 7%, Giant 4%, Prismatic 1%, Normal 88%. Show odds in journal/info panel. Use serverless local pseudorandom generator; save outcome as soon as decided so reload cannot reroll it. Journal tracks species x variant discovered (6x4=24 entries). Never sell mutations for real money in MVP.

Decorations: Pebble Path 80 coins, Mushroom Lamp 160 coins, Tiny Fountain 350 coins. Decoration purchase is permanent; place only in designated decoration slots outside plots; placement persists. No collisions with UI or plot interaction.

## 5. WORLD LAYOUT AND CAMERA
Portrait world with centered 3x3 diamond-shaped garden, visual depth through isometric 2D tiles. Screen zones: top HUD (coins, journal progress, settings); central garden (~55% height); bottom contextual action bar with Shop, Garden, Journal. UI safe-area margins >= 24 design px and tappable targets >= 48x48 dp equivalent. Use canvas scaling for devices 19.5:9 to 16:9. Plot tiles in staggered diamond layout, with back rows rendered before front rows (y-sort). Plot hit areas generous and non-overlapping. On tap: subtle plot highlight and floating context card. On drag: optional gentle camera pan only if needed; MVP garden should fit without zoom. Do not introduce hidden off-screen essential controls.

Visual hierarchy: plots and plant silhouettes are primary; UI secondary. Environment includes softly shaded soil, grass border, tiny rocks, ambient fireflies at dusk (cosmetic only). No copyrighted Hay Day assets or matching trade dress. Use coherent original silhouettes.

## 6. ART DIRECTION / ASSET SPEC
Art style: original cozy storybook 2.5D, soft pastel palette, rounded geometry, chunky readable silhouettes, subtle hand-painted gradients, light outlines, warm sunlight from upper-left, ambient occlusion painted into sprites. Color palette suggestions: grass #8BCF8A, soil #9A6A52, sky accent #D8F0E5, cream #FFF7E8, dark text #273C36, gold #F5C45E, pink #F4A6C8, cyan #81DDE1. Ensure WCAG-like contrast for text (target 4.5:1). Fonts: use a redistributable open-license rounded sans font and record license in `assets/LICENSES.md`.

Each plant needs 4 growth-stage sprites: seed mound, sprout, young plant, mature plant. For six species: 24 base stage sprites. Mutation overlays or shader variations must keep silhouettes recognizable; Giant needs safe bounds so it does not obscure neighbors' tap targets. Each plot: dry, watered, growing, ready highlight. Decorations: idle and one small reactive animation each. Provide an asset manifest with exact filenames and pixel dimensions. Target native art size ~256x256 px per plant stage, plots ~384x192 px, UI icons 96x96 px; export PNG with transparency. If finished art cannot be generated in the code environment, make attractive, cohesive procedural vector/Polygon2D placeholder assets with clean silhouettes, not broken external URLs or mismatched stock photos. Record asset replacements as TODOs.

## 7. ANIMATION SPECIFICATION (ALL DURATIONS IN SECONDS)
Use Tween/AnimationPlayer, eased curves; prefer transform/opacity over expensive particle counts. All animation should remain responsive and skippable. Reduced-motion mode disables camera shake, excessive pulsing and particles, replacing them with simple fades.

| Event | Motion | Duration | Easing / constraints |
|---|---|---:|---|
| Boot logo | opacity 0->1, slight 0.96->1 scale | 0.45 | ease-out cubic |
| Menu entry | cards rise 18 px and fade | 0.35 stagger 0.06 | ease-out |
| Plot tap | plot scale 1->1.06->1 | 0.18 | ease-out-back, no camera shake |
| Seed selection | seed icon flies to plot in curved arc | 0.42 | ease-in-out cubic |
| Planting | soil puff + seed pop | 0.48 | <=8 particles |
| Watering | watering can tilt 20 degrees + 3 droplets | 0.65 | droplets stagger 0.08 |
| Watered soil | brief darker tint, tiny shine | 0.35 | no strobe |
| Growth stage change | squash/stretch 0.9->1.08->1, crossfade | 0.50 | ease-out-back |
| Mature ready | subtle vertical bob +/- 3 px | 2.4 loop | sine, pause offscreen |
| Harvest tap | plant bounce, then shrink/fade into inventory | 0.55 | ease-in-out |
| Coin gain | 3 coin icons arc to HUD, HUD number count-up | 0.75 | <=3 icons, count-up 0.4 |
| Normal discovery | journal card slide and glow | 0.65 | once per new entry |
| Golden reveal | warm radial halo, 8 sparkles | 1.10 | no flashing >3 Hz |
| Giant reveal | grow from 0.85 to 1.35 with bounce | 0.90 | safe visual bounds |
| Prismatic reveal | hue-shift shimmer, 12 sparkles | 1.30 | low contrast, reduced motion fallback |
| Shop open/close | bottom sheet translate 24 px + fade | 0.28 | ease-out cubic |
| Purchase success | button pulse + tiny checkmark | 0.38 | no modal spam |
| Purchase failure | horizontal shake +/- 5 px twice | 0.26 | replace with text for reduced motion |
| Tutorial pointer | gentle up/down 6 px | 1.4 loop | stop once step completed |
| Decoration place | 0.7->1.1->1 scale + dust | 0.48 | ease-out-back |
| Save indicator | small check fades in/out | 0.7 | never blocks taps |

Idle ambient effects: plant leaf sway +/-2 degrees with 3–5 s randomized periods; 2–4 floating pollen particles maximum; fountain cycles 2 s; lamp glows with 3 s slow pulse. Pause animations in hidden scenes and when app backgrounded. Respect OS battery-saving where possible. Limit simultaneous particles to ~40 on screen.

## 8. UI SCREENS AND MICROCOPY
**Boot:** logo, loading progress, graceful error recovery; no fake loading. On first launch show short 3-step tutorial. On returning launch restore garden.
**Garden:** top-left coin balance, top-right journal completion (e.g. 3/24) and settings; plot badges show remaining time (MM:SS under 1h, H:MM over 1h), mature sparkle; bottom nav Garden / Shop / Journal. Plot card: species name, growth stage, timer, Water or Harvest; empty plot opens seed picker. Buttons show disabled states with reason.
**Seed picker:** cards with illustration, seed name, price, growth time, inventory count, Buy / Plant; if locked show unlock requirement, no mystery purchases.
**Shop:** Seeds and Decorations tabs; item preview, exact coin price, purchase confirmation only for costly decorations (>=160), toast on success; insufficient coins prompt to harvest, not real-money purchase.
**Journal:** 24 grid entries, undiscovered silhouettes with `???`, discovered full art, rarity labels, date first discovered, species description; progress 0/24 to 24/24. Filters: All, Normal, Golden, Giant, Prismatic. Accessibility text labels for color-coded rarity.
**Settings:** music volume, SFX volume, haptics, reduced motion, notifications opt-in, reset progress (two-step confirmation), credits, privacy note stating no data transmitted in MVP.
**Pause/help:** concise controls and gameplay explanation. No account or internet required.
Microcopy examples: `Plant a seed`, `Ready to harvest!`, `New discovery!`, `Not enough coins`, `Growing: 04:32`, `You found a Prismatic Glowberry!`, `Your garden grew while you were away.` All strings centralized for future localization.

## 9. TUTORIAL (TARGET UNDER 90 SECONDS)
Step 1: highlight empty plot, text `Tap a plot to plant your first seed.`
Step 2: highlight Moon Daisy seed, text `Choose a seed. Each plant grows at its own pace.`
Step 3: show watering can, text `Water once to give it a little boost.`
Step 4: for tutorial-only plot, use a 5-second growth timer (explicit exception, never change normal plant data), text `Your first plant is ready!`.
Step 5: tap Harvest, reveal coins and journal entry, text `Harvest plants, discover mutations, and grow your collection!`.
Step 6: point to Shop, text `Spend coins on more seeds and decorations.` Finish, dismiss pointer, persist tutorial_completed. Allow skip after first screen. Tutorial must not permanently consume scarce starting resources in a way that soft-locks progression.

## 10. GAME RULES / STATE MACHINE
Plot states: EMPTY -> PLANTED -> GROWING -> READY -> HARVESTED -> EMPTY. Water is a boolean modifier while GROWING, not a separate plot state. Each plot has unique ID, species_id, planted_at_utc, ready_at_utc, watered, mutation_roll_seed/outcome, harvest_claimed flag. Only READY can harvest. Water can happen at most once per crop; water reduces *remaining* grow time by 10% when applied, with minimum remaining time 1 second. Growth stage thresholds at 0%, 25%, 60%, 100%. Timer UI computed from max(0, ready_at_utc - now_utc). When resumed, recalc immediately and transition to READY; never spawn reward until explicit harvest action. Guard repeated harvest taps with a synchronous state transition before any animation. Coins cannot be negative; inventory values integers >=0. All purchase/plant/harvest operations atomic in game logic, then persist.

## 11. SAVE / TIME / OFFLINE INTEGRITY
Store JSON save under `user://save_v1.json` with schema_version, last_saved_at_utc, coins, seed_inventory, harvested_inventory, plots, journal_discoveries, decorations, settings, tutorial_completed, statistics and a unique local save ID. Write via temp file then atomic replacement where supported; keep `save_v1.backup.json` last known good. Validate types and clamp corrupt values; if save fails, show nonblocking but clear warning and retry. Migrate future schema versions explicitly. No external database or user tracking. Handle app suspend, resume, quit, force close. Use UTC Unix seconds and monotonic time during a foreground session to mitigate wall-clock adjustments. Offline clock manipulation cannot be fully prevented without a trusted server: document limitation and avoid punitive anti-cheat. If clock moves backwards, freeze negative elapsed time and show consistent state. Unit tests must cover time jumps, save corruption, double-tap harvest and negative currency prevention.

## 12. AUDIO / HAPTICS
Music: original/royalty-free licensed gentle loop, ~75–95 BPM, soft plucked instruments, volume default 35%, seamless looping. SFX: soft plot tap (60–100ms), planting plop (~250ms), watering trickle (~600ms), harvest pop (~300ms), coin chime (~450ms), rare discovery gliss (~900ms), shop purchase (~200ms), error soft thud (~180ms). Avoid harsh high-frequency sounds. Master, music, SFX sliders; mute persists. Haptics: light on planting/harvest, medium on rare discovery, none if disabled. No music or asset copying from existing games.

## 13. ACCESSIBILITY AND RESPONSIVENESS
Touch target >=48 dp equivalent; text body >=16sp equivalent; large readable numbers; avoid conveying rarity solely by color; reduced-motion setting; adjustable music/SFX; screen reader-friendly labels where Godot/platform support permits; UI scales to 720x1280, 1080x1920, 1170x2532 and 1440x3200 without clipping; handle safe areas. Tutorial not dependent on hearing. Maintain 4.5:1 text contrast where feasible. No mandatory precision drag gestures.

## 14. PERFORMANCE AND QUALITY
Target <150 MB installed if possible; <=3 s cold-start on typical mid-range Android (aspirational benchmark, measure rather than claim); 60 FPS target with 30 FPS fallback; avoid allocations in `_process`; use shared timer, pooling for particles, atlases and preloaded frequently used assets. Check pause/resume after 24h, low memory, no internet, 100 repeated taps, different aspect ratios, no clipping, no duplicated rewards. Add debug overlay only in development builds: FPS, current scene, selected plot, save status.

## 15. PRIVACY / LEGAL / RELEASE READINESS
No user accounts, no personal data collection, no third-party SDKs in MVP. Document locally stored gameplay data and reset option. Record licenses for all third-party fonts/audio/art. Keep original branding and original assets; avoid misleading claims. For Google Play prepare signed Android App Bundle, store listing, icon, screenshots, content rating, privacy policy consistent with actual behavior and data safety disclosures. For iOS plan Xcode/macOS export, provisioning, store metadata and platform compliance; do not claim iOS builds were tested without macOS/Xcode. If monetization is added later, use store-compliant in-app purchases and required consent flows, not external checkout inside the game.

## 16. FUTURE MONETIZATION (NOT IMPLEMENTED IN MVP)
Phase 2 only after engagement metrics support it: optional rewarded video for one-time 20% growth reduction or extra cosmetic coins, capped to avoid ad fatigue; optional decorative packs for $1.99–$4.99, never random paid loot boxes; optional one-time remove-ads purchase only if interstitials ever exist. Avoid subscriptions until there is ongoing content value. Add privacy disclosures, consent and parental/age considerations before integrating any ad SDK. Treat all prices as hypotheses. Do not implement simulated ads or fake purchase screens in MVP.

## 17. QA / ACCEPTANCE TESTS
Automated tests or runnable scripted test harness must cover:
- fresh launch initializes exactly 9 empty plots and correct starting inventory/currency;
- tutorial can be completed and skipped; no soft-lock;
- plant action consumes exactly one seed and sets positive future ready timestamp;
- water can be used once only, reduces remaining time once;
- after advancing mocked time beyond ready_at, plot becomes READY;
- harvesting once increments harvested inventory and journal correctly;
- 20 rapid harvest taps produce only one reward;
- mutation probabilities sum to 100% and each harvest yields at most one mutation;
- mutation outcome persists across save/load;
- purchases never make coin balance negative;
- unlock thresholds work at 5/15/35 total harvests;
- save/load restores coins, plots, timers, inventory, decorations, journal, settings;
- corrupt save triggers backup/recovery, not silent data loss;
- offline 48h resume progresses all planted plots correctly;
- backward device clock does not create negative timers or double rewards;
- settings toggles persist;
- UI works in narrow/tall screens with safe areas;
- reduced motion replaces high-motion animations;
- no network required to play.
Manual smoke tests: boot, complete tutorial, plant all nine plots, water, close/reopen, advance time using test clock, harvest, buy seeds, unlock species, discover variant using debug seed, buy and place decorations, toggle sound, reset with confirmation. Record pass/fail in `docs/QA.md`.

## 18. IMPLEMENTATION PHASES AND GATES
**Phase 0 — Repository audit / foundation:** inspect repo; create Godot project if empty; add `.gitignore`, README, license notes, project folders, typed data models and a runnable empty garden scene. Gate: Godot opens and runs with no errors.
**Phase 1 — Vertical slice:** one plot, Moon Daisy, plant -> water -> grow -> harvest, coin update, local save/load, polished touch interactions. Gate: 10 successive cycles and restart persistence.
**Phase 2 — Complete gardening:** nine plots, all six species, seed inventory, growth timers, unlocks, shop and responsive HUD. Gate: all basic gameplay tests pass.
**Phase 3 — Mutations / journal:** Golden/Giant/Prismatic outcome generation, visuals, 24 journal entries, discovery overlays and rarity presentation. Gate: deterministic test seeds and save/load verified.
**Phase 4 — Art / animations / audio:** coherent sprite placeholders or licensed final assets, all animations from section 7, sounds, decorations, polish. Gate: consistent visual style and acceptable performance.
**Phase 5 — Tutorial / settings / accessibility:** first-run tutorial, reduced motion, audio controls, reset, safe areas, no network. Gate: fresh-user flow under 90 seconds, no blockers.
**Phase 6 — QA / Android release candidate:** automated and manual tests, fixes, README build instructions, Android export configuration, screenshots, final acceptance report. Gate: build/export only if available; explicitly document remaining blockers.

After each phase, produce: list of changed files, architecture summary, manual verification steps, test results (pass/fail/not run), known issues and proposed next phase. Never skip a failing gate to add more features.

## 19. DEFINITION OF DONE
A player can install/run the game, complete tutorial, plant and water six species across nine plots, close and reopen without losing progress, harvest with correct rewards, discover three variants, collect 24 journal entries, buy and place three decorations, toggle settings, and play fully offline. Interface feels cohesive on portrait devices, key animations work and respect reduced motion, no known data-loss or reward duplication bugs, and QA/release instructions are documented. No placeholder buttons that do nothing, no false claims of store readiness.

## 20. FIRST CODEX MESSAGE (SEND THIS WITH THE DOCUMENT)
Read `Mutant_Garden_Codex_Technical_Spec.md` completely. Start with Phase 0 only. Inspect the GitHub repository and existing code. Create `docs/PLAN.md` describing the architecture, scenes, data resources, test strategy, major risks and implementation sequence. Then implement the minimal Godot project scaffold with a working boot -> garden scene, original simple isometric 3x3 plot placeholders and responsive portrait HUD. Do not start Phases 1–6 until I review Phase 0. Run whatever checks are available and report exact commands/results. Commit changes in a small logical commit or prepare a PR, depending on available permissions. Do not add external dependencies without explaining why.
