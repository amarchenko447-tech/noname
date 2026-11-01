# Foundation visual direction
Original soft storybook garden, cream paper UI and mint background. Sun from upper-left; warm soil layered above a grassy diamond island. Rounded panels and generous text. World rendering is procedural static vector geometry, no generated raster art or stock assets.

Palette: ink #273C36; cream #FFF7E8; grass #8BCF8A; soil #9A6A52; gold #F5C45E; background #D8F0E5. Supporting text #4D685C on cream. Open Sans regular is bundled and licensed locally; a more rounded redistributable typeface can be evaluated during polish.

## Asset manifest
- scripts/ui/garden_world.gd: vector island, nominal bounds 1028×642 design px, transparent outside geometry.
- Same file: nine vector beds, each 296×160 including side wall; 292×144 diamond hit area.
- Same file: vector soil furrows, border daisies and pebbles; no external art files.
- scripts/ui/garden.gd: cream rounded UI panels, resolution-independent.
- assets/fonts/OpenSans-Regular.ttf: bundled Open Sans regular, variable raster dimensions.

## Replacement TODOs (Phase 4)
Hand-author 24 plant-stage PNGs at 256×256, plot sprites at 384×192, icons at 96×96; record exact filenames as produced. Keep transparent bounds and nonoverlapping hit regions. Implement mutation overlays with readable labels, safe Giant bounds and reduced-motion-safe shimmer. Add decoration sprites and reactive animations, original/licensed sounds and soundtrack. Do not claim these exist in Phase 0.
