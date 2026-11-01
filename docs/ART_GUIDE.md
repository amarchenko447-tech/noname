# Phase 0.5 visual direction and asset manifest

Original cozy storybook illustration built with local Godot vector drawing.
Warm morning light, cream paper UI, sage meadow and dimensional terracotta soil.
Rounded corners, fine warm soil flecks, inset furrows and pale timber rims integrate
the beds into a planted border. Small flowers, clustered foliage, mushrooms,
pebbles, a stepping-stone path and fence/sign frame the garden without covering soil.
No generated imagery, stock photos or copyrighted game assets are used.

## Palette and hierarchy
- Ink #294C3C, supporting text #52634C, paper #FFF9E9.
- Meadow #B1D597, moss #85B77A, foliage #679971 / #8CB77B.
- Soil #674733 / #82563C / #8F6041, sunlit ridge #A9744D.
- Timber #E4C38E, coral mushroom #D27C65, pale flowers #FFF5DC.
- Primary button #496D4A with cream lettering; selected bed has an outside warm ring.
Primary reading order: brand, garden, selected bed/action. Coins and level are
compact top cards. Navigation uses original outlined icons plus text.

## Manifest
| File | Artwork | Nominal dimensions |
| --- | --- | --- |
| scripts/ui/garden_backdrop.gd | Vertical warm-sky/meadow gradient, low-contrast hedge silhouettes, meadow flecks | Viewport-scaled |
| scripts/ui/garden_environment.gd | Turf island, shadows, seeded grass texture, trees/bushes, fence, translated sign, flowers, mushrooms, stones/path | Approx. 1110×990 world units including margins |
| scripts/ui/garden_bed.gd | Nine independently cached soil tiles with seeded flecks, furrows, moss and raised rims | 294×214 world units per tile |
| scripts/ui/garden_drawing.gd | Rounded polygons, ellipses, leaves and flower primitives | Resolution independent |
| scripts/ui/garden_ambience.gd | Animated grass/flowers, two butterflies, three pollen motes, sunlight caress | Garden bounds |
| scripts/ui/garden_icon.gd | Original line gear/book/leaf/help/close icons | 24×24 logical, inside ≥48×48 controls |
| scripts/ui/garden.gd | Rounded/shadowed panels, buttons, focus rings and safe-area layout | 390×844 logical reference |
| assets/fonts/OpenSans-Regular.ttf | Licensed Open Sans regular | Scalable font |

## Animation budget
Static artwork is cached by CanvasItem and repainted only for a relevant change
(e.g. locale for sign). Independent soil nodes move for selection; they do not
regenerate their seeded textures every frame. The lightweight ambience and ring
request redraw at 30 Hz. There are no physics particles, shader dependencies,
network art requests or gameplay timer polls.

Grass loops 3.5–4.5s, flowers gently bob, two slow butterflies and at most three
pollen motes animate. Sunlight shimmer is a restrained 9s envelope. Selection is a
deterministic 180ms sine-eased lift/scale, with a 2.8s soft ring pulse. Repeated taps
restore the previous bed before starting the next selection. Geometry/hit regions
remain fixed throughout animation. Reduced motion freezes ambient movement and
ring pulse and removes bounce, retaining immediate static selection feedback.
Hidden/backgrounded scenes stop ambient animation work.

## Future artwork
Plant-stage sprites, mutation visuals, purchasable decoration art and audio remain
later phases. The mushrooms/fences here are environmental scenery, not purchases.
If replacing vector art with PNGs, preserve touch geometry and record exact file
names, transparent bounds, dimensions and provenance. Profile devices before
claiming frame rate or mobile performance.
