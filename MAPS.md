# Continent maps: geometry, hit testing, and client ports

Read this guide before changing map boundaries, rebuilding map assets, adding a continent, or preparing the Forever maps. The current packaged geometry targets **Retail artwork with Classic outdoor destinations**. It is an artwork-derived estimate, not a verified export of Forever boundaries. Keep stable destination IDs and gameplay progression independent of client map IDs.

## Files and responsibilities

| File | Responsibility |
| --- | --- |
| `Assets/Maps/regions.json` | Editable Retail manifest: artwork identity, coarse land guides, interior markers, and reviewed inland water |
| `scripts/prepare_map_masks.py` | Assemble client artwork, generate one ownership partition, constrain hit areas, and produce masks, metadata, Lua, and review images |
| `Assets/Maps/retail/*.tga` | Generated, padded RGBA masks; do not hand-edit |
| `Assets/Maps/retail/geometry.json` | Generated audit data: masks, centers, region names, run-length rows, and provenance |
| `Compatibility/MapMasks.lua` | Generated `W.MapGeometry.retail` runtime data; do not hand-edit |
| `Compatibility/Maps.lua` | Client map discovery, artwork checks, ownership lookup, texture paths, native fallback, and explicit native export |
| `Compatibility/Client.lua` | Client detection, client-specific continent and zone IDs, and native artwork loading |
| `UI/Atlas.lua` | Tile rendering, mask projection, mouse-coordinate conversion, tooltips, and travel |
| `tests/map_masks.py` | Pixel ownership, coast/water eligibility, borders, mask projection, and generator/import regressions |
| `tests/client.lua`, `tests/zones_ui.lua` | Runtime lookup, export behavior, scaled map interaction, unlock states, and native full-texture mask projection |

Raw extracted game textures, native-query exports, screenshots, and tool installations stay **outside the repository**. Generated mask derivatives and geometry descriptors belong in the addon. Python 3 and Pillow are sufficient for generation; the addon does not run Python or sample the world continuously.

## Coordinate and ownership contract

The manifest's `canvas` is the logical raster, currently `1200 × 800`. Coordinates in `land`, `caps`, `seeds`, and `inlandWater` are pixels in that canvas, with the origin at the top left. They are not world coordinates or screen pixels. A runtime point `(x, y)` is normalized to `[0, 1]`; lookup uses `floor(x * width)` and `floor(y * height)`, bounded to the last pixel. Generated centers use pixel centers, `(column + 0.5, row + 0.5)`, then normalize them.

Each raster pixel has at most one owner. Masks and clicks derive from that same field. Generated ownership rows are strings such as `30:0,12:2,18:0`: each pair is `length:regionIndex`, lengths sum to the canvas width, `0` means no region, and positive indices address Lua's one-based `names` list. Python subtracts one when decoding. Excluded names start with `_`; they can own land in the partition but are absent from `Content.zoneByID`, so they are not travel destinations.

Hover first resolves the owner through those rows, then displays that destination's generated mask with the same full padded projection as its color overlay. Do not use native highlight textures for a packaged partition: native highlights can merge narrow passes or disagree with the artwork-derived ownership. Native highlights remain a fallback only when no matching packaged geometry is available.

**Mask bounds are not hit rectangles.** `masks[zone].bounds` positions a GPU texture, including transparent padding. Bounds may extend beyond the map's normalized right or bottom edge. Never use them for click detection, clamp them to `[0, 1]`, or stretch them to fit a zone. Runtime clicks use the generated rows.

## Generation pipeline

1. Assemble the client tiles described by `artwork`. The current helper expects numbered BLP tiles, `<directory>/<directory>1.blp`, and so on. It derives tile placement from `size` and `tiles`.
2. Match the artwork actually shown by `Client.MapTileTexture`. Retail currently replaces selected title tiles with matching unlabeled flight-map tiles. The Python helper and Lua renderer must make the same replacements. Do not assume a different client or continent has matching tile names or artwork.
3. Classify land from the artwork palette within coarse shoreline guides. This separates land from sea and parchment. Small enclosed holes are filled and detached thin horizontal sea-hatching components are removed without discarding round offshore islands. `caps` limit the guide's search margin near warm parchment.
4. Run a multi-source geodesic watershed from `seeds`, favoring paths that do not cross narrow dark border strokes. All zones and excluded regions compete in one field. Unseeded offshore components inherit a nearby owner. A small mode filter removes narrow decorative paths.
5. If `--client-data` is supplied, import native ownership from the matching client/artwork. Native owners take precedence. Classic subdivisions missing from that export retain artwork-derived ownership; `fallbackZones` records them.
6. Clip the final **click field** to classified land plus reviewed `inlandWater` polygons for the *same owner*. The coarse propagation domain deliberately spans icon holes and shore margins; it must never become the hit box. Open sea and parchment remain unclickable. Retail's flooded Thousand Needles needs explicit water support; a dry Forever map may not.
7. Clip each color mask to land. Water can be clickable without becoming desaturated. Apply a shared antialiasing kernel, pad to power-of-two dimensions, and generate the Lua and JSON descriptors from that same partition.

A marker must lie inside its intended zone and away from lake icons, city symbols, border strokes, or neighboring terrain. Markers influence the entire watershed, not just a local circle. Use additional interior markers for long or narrow regions. A marker in a neighboring zone can steal a large area even when every texture is technically valid. Review both sides of the boundary after every marker change.

### Manifest fields

| Field | Meaning |
| --- | --- |
| `profile` | Client flavor key, currently `retail`; must match `Client.flavor` |
| `canvas` | Logical width and height shared by this manifest's continents |
| `artwork[continent]` | Source `directory`, native `mapID`, full artwork `size`, tile grid `tiles`, and verified `firstTexture` FileDataID |
| `land[continent]` | Lists of coarse closed shoreline guide polygons, including offshore islands |
| `caps[continent]` | Rectangles limiting guide expansion near decorations/parchment |
| `seeds[continent][zone]` | One or more `[x, y]` interior markers; use stable content IDs or `_excluded_name` |
| `inlandWater[continent][zone]` | Lists of closed water polygons that may remain clickable only when that pixel's owner is this zone |

Keep inland-water polygons tight. They are explicit exceptions to land-only hit eligibility, not a way to enlarge a destination across a coastline. An unknown water owner is an error. Do not add ocean polygons to make a bad marker or boundary appear selectable.

## Rebuild and correct a boundary

From the repository root, with contributor-supplied paths:

```sh
python3 scripts/prepare_map_masks.py \
  --source-dir "$MAP_ART_SOURCE_DIR" \
  --preview-dir "$MAP_REVIEW_DIR"
stylua Compatibility/MapMasks.lua
python3 tests/map_masks.py
lua5.1 scripts/test.lua
```

`MAP_ART_SOURCE_DIR` is an extracted `interface/worldmap` directory. For current Retail title replacements, also supply its sibling `interface/adventuremap` directory. The defaults write profile-specific textures and audit metadata under `Assets/Maps/<profile>` and Lua to `Compatibility/MapMasks.lua`. Use `--regions` for a different manifest, `--output-dir` for a temporary regeneration comparison, and `--lua-output` for a separate client descriptor.

Review all generated images, not just an all-unlocked map:

- `<continent>.png`: color-coded ownership overview with markers.
- `<continent>-destinations.png`: each destination's visible land mask in isolation.
- `<continent>-hit-regions.png`: cyan clickable areas, including supported inland water. This exposes invisible coastal overshoot that a color-only sheet cannot show.

For a reported boundary defect, locate the cursor point on this raster, inspect the owner row and original artwork, and check neighboring markers. Correct the editable manifest, rebuild, and add interior samples **on both sides** to the regressions. Also test nearby open water returns no destination. Never patch generated rows or fix only a texture: that separates visuals from behavior.

For a read-only runtime probe, convert a reviewed pixel to its normalized pixel center. For example, the current Retail Darkshore regression uses:

```lua
/run local z=WoWIdle.Client.ZoneAtPosition("kalimdor",552.5/1200,170.5/800); print(z and z.name or "none")
```

Use that manifest's canvas dimensions for other profiles. A probe in an ocean margin should print `none`. The query does not travel or alter state.

Review the changed destinations and their neighbors, as one marker can move several shared edges. Confirm ordinary zones have not collapsed into decorative icons, excluded regions have not been borrowed, narrow passes remain selectable, and offshore components retain appropriate owners. Rebuild into a temporary directory and compare bytes when changing generator behavior.

## Native data export

In the actual supported client:

```lua
/run WoWIdle.Client.ExportMapGeometry()
```

This explicit developer action samples `C_Map.GetMapInfoAtPosition` at pixel centers over multiple frames, resolves known destinations through their native map ancestry, and opens a copyable JSON result. Close the window to cancel. It neither sends data nor changes SavedVariables. An optional callback and dimensions are available for tests/developer tools: `ExportMapGeometry(onDone, width, height)`, with dimensions bounded to `16..1200` by `16..800`.

Save the copied JSON outside the addon, then generate with:

```sh
python3 scripts/prepare_map_masks.py \
  --regions "$MAP_MANIFEST" \
  --source-dir "$MAP_ART_SOURCE_DIR" \
  --client-data "$MAP_QUERY_EXPORT" \
  --preview-dir "$MAP_REVIEW_DIR" \
  --lua-output "$MAP_LUA_OUTPUT"
```

The export contains `version`, `profile`, `build`, and `continents`. Each continent supplies `mapID`, `artSize`, `firstTexture`, sample `size`, `names`, and row runs of `[length, label]`. **Export labels are zero-based**, with `-1` for no native result; this differs from generated Lua rows. Unknown native maps receive `_map_<ID>` names. The importer validates profile, map ID, dimensions, texture identity, row widths, labels, and names before use.

Check split, renamed, localized, and phased native maps before trusting an export. The current exporter starts with one verified native ID per destination and walks native ancestors; it does not automatically recognize every renamed sibling map as the same Classic zone. Add verified client-specific aliases where necessary, then check every destination in the exported result. A partially recognized split region can otherwise become an excluded `_map_<ID>` area.

Check `source` and `fallbackZones` in the generated audit metadata. A native export is not proof that every Classic boundary exists as a separate native region. Merged regions still need review. Do not use `GetMapRectOnMap` world rectangles as painted borders. Current simulator builds do not implement every native map query; a successful mock export or simulator screenshot is not a live-client export.

## Rendering constraints and live checks

The runtime selects `W.MapGeometry[Client.flavor]` and checks the continent ID, artwork dimensions, and first texture before using its masks. Mismatched artwork does not receive a stale partition; native map lookup remains the fallback. Client IDs are discovered from that client's hierarchy or verified compatibility tables, never copied blindly between clients.

Masks use full texture coordinates, transparent-black clamping, and identical RGB/alpha channels. Their complete padded texture is positioned at the source pixel scale. **Do not restore cropped mask UVs.** Cropped-mask projection previously looked correct in the simulator while shifting gray regions over the sea in the live client. Keep all channels zero outside the shape and preserve the padding/placement tests.

Restart the game after replacing texture files, then check the actual client. Hover and click each side of corrected borders; confirm no tooltips or travel over open sea, and verify supported inland water. Check locked, partly unlocked, and all-unlocked states in fullscreen and windowed modes. The compact World map control opens the larger map; check that transition as well. Unlocks follow `runBest`, not the party's hero levels. One useful fixture is five level-4 heroes in Westfall at encounter 31: level-9 enemies and frontier 9, with level-10 destinations still locked. No geometry change should alter progression or unlock rules.

## Forever port checklist

1. Read `AGENTS.md`, this guide, and `TOOLING.md`. Update the Forever simulator/client versions and testing setup together before using that simulator.
2. Verify `GetBuildInfo`, flavor detection in `Compatibility/Client.lua`, supported TOC metadata, and the actual map APIs. Confirm native continent/zone IDs and artwork identity in that client.
3. Create a **separate manifest** with `profile: "forever"`, its own canvas, tile layout, shoreline guides, markers, exclusions, and inland water. Do not reuse Retail coordinates, flooded geography, or title-tile substitutions without checking them against Forever artwork.
4. Export native ownership in Forever and regenerate from its textures. Inspect every fallback subdivision and all hit-region sheets. Remove Retail-specific excluded regions or water exceptions where they do not exist.
5. Write a separate Lua descriptor, for example `Compatibility/MapMasksForever.lua`, and load it alongside the Retail descriptor in the TOC after `Compatibility/Maps.lua`. Each generated file adds its own profile to `W.MapGeometry`; it must not replace the table. The default output path is still the Retail descriptor, so pass `--lua-output` deliberately.
6. Extend profile-specific tests and run geometry, Lua syntax, StyLua, Lua Language Server, simulator interactions, and actual Forever checks. Existing pixel fixtures and the 41-destination assertion target Retail/Classic content and need deliberate extension if that roster changes.

## Adding a continent

Generation is data-driven, but the current runtime and exporter still have two-continent integration points. Audit all of them:

1. Add stable destinations and their enemies, bosses, loot, backdrops, and model mappings in the content/compatibility catalogs. Preserve old IDs and saves.
2. Add the continent's verified client IDs to `Client.profiles`, its discovery name in `Compatibility/Maps.lua`, and its export task in `ExportMapGeometry`. Update the exporter progress count, currently `/ 2`, and its two-task tests. The discovery roots currently checked are `947` and `946`; verify they cover the new client's hierarchy.
3. Add artwork, guides, seeds, excluded regions, and any inland water to the correct profile manifest. If source filenames, tile dimensions, layers, atlases, or aspect ratio differ, update `artwork()` and native loading appropriately. Keep generator assembly and runtime `MapTileTexture` substitutions identical.
4. Add continent navigation/paging in `UI/Atlas.lua`. The current layout explicitly creates two 632-pixel map panels; adding a third panel in the same row would overflow. Preserve cursor scaling, clipping, hover cleanup, and direct travel.
5. Generate and package assets and the correct profile descriptor. Extend content/geometry coverage tests, export tests, scaled interaction tests, and boundary/coast probes for the new continent. Review all hit and mask sheets, then validate the actual client.

Link any new profile manifest, descriptor, or new integration points back into this guide so the next maintainer can find them.
