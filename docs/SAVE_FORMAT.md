# Farm snapshots

The file remains user://world_v1.json for compatibility, but its root schema is now 2.
One atomic snapshot contains `world` (map schema 1, IDs/coordinates/occupancy data),
`gameplay` (coins, crops referencing stable plot IDs, last cycle per plot, statistics),
and `last_observed_utc`. Preferences remain in settings_v1.cfg and are never migrated
or overwritten by gameplay commands.

WorldSnapshotStore accepts an explicit target version. WorldService targets version 2
and registers migration 1→2: wrap the accepted Phase 0.75 map unchanged, initialize
150 coins and no crops. The generic map-only codec/tests can still target schema 1.
Future versions are rejected before trying older backups, preventing downgrade.

A crop stores species_id, plot_id, cycle_id, planted_at_utc, ready_at_utc and cached
stage/readiness. Timestamps are authoritative; cached fields are recomputed on load.
Coins and crop removal are committed together before reward effects. Expected cycle
checks reject stale taps even after a new crop is planted. A failed write leaves
live currency/crops unchanged; temp files are never treated as completed saves.

TimeService uses UTC for closed-app progression and a monotonic foreground anchor,
with a saved observed-time floor. Backward clocks cannot rewind crops or rewards.
No trusted-server anti-cheat guarantee is claimed for an offline game.
