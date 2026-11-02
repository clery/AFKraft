# Development tools

## Requirements

- Lua 5.1 for domain and simulation tests.
- A supported World of Warcraft client for integration checks.
- Optional: [WoW UI Simulator](https://github.com/Osso/wow-ui-sim) for frame inspection, screenshot capture, and addon tests outside the client.

## Simulator setup

Use the Retail simulator package for all current addon development and visual testing. Do not use the Forever package while its UI-source version mismatches the installed client. When Forever development begins, update the simulator version and testing setup together before switching targets. Set `WOW_INSTALL_PATH` to the World of Warcraft installation root containing its shared `Data` directory. The simulator and client must have compatible UI-source versions. A source-version mismatch is distinct from a missing installation path.

Keep tool binaries, downloaded dependencies, game assets, installation paths, screenshots, and logs outside the repository. Use a dedicated addon root containing this addon and only its required dependencies.

```sh
wow-sim-retail --addons-path "$ADDON_ROOT" --no-saved-vars screenshot --png \
  --width 1280 --height 720 --output "$SCREENSHOT_PATH"
```

`ADDON_ROOT`, `WOW_INSTALL_PATH`, and `SCREENSHOT_PATH` are environment-specific values supplied by the contributor. Do not commit their values.

## Client compatibility

Retail is the initial development target; Forever remains the intended content target. Share simulation, inventory, crafting, talents, persistence, and interface code. Isolate client detection, map and model identifiers, and real-world activity rewards.

Matching model and map API declarations do not guarantee identical runtime behavior. Verify character models, animations, combat restrictions, map artwork, and reward-event payloads in each actual client. Simulator screenshots establish layout behavior; successful model API calls alone do not establish correct model rendering.

The simulator may lack scenery actor loading even when the client exposes `SetModelByFileID`. The experimental model renderer reports this through its capability state. Screenshot backdrops are currently enabled instead and can be checked in the simulator. Character models still need in-client verification. Painted backdrop substitutes are not used.

## Screenshot assets

The addon bundles 24-bit, uncompressed TGA backdrops for all current destinations. `Assets/Backdrops/sources.json` records their public source URLs and vertical crop positions; `Assets/Backdrops/SOURCES.md` contains the attribution table.

Asset preparation requires Python 3 and Pillow. Keep downloaded originals outside the repository and supply their directory explicitly:

```sh
python3 scripts/prepare_backdrops.py --source-dir "$SCREENSHOT_SOURCE_DIR" --download
python3 scripts/prepare_backdrops.py --check
```

The first command downloads the recorded originals and rebuilds the packaged textures. Omit `--download` to use existing originals named after their destination IDs. The second checks texture dimensions and color format without downloading anything. Run StyLua afterward if the texture descriptor changes.

## Visual checks

Check fullscreen, expanded, and compact sizes; text clipping; map tiles; tab changes; party composition; locked-window access; and offline progress summaries. Repeat checks after UI changes. Do not commit game assets or environment logs.

## Native combat visuals

Combat spell effects use native M2 model files through ModelScene actors, with FileDataIDs isolated in `Compatibility/SpellEffects.lua`. Spell IDs and SpellVisualKit IDs are different namespaces; do not substitute one for another. Spell models use an explicit side camera and a drawable one-pixel viewport during loading. The final viewport has triple padding with a proportionally increased camera distance to preserve apparent size, and is sized before camera setup. Combat effects use explicit world-space camera axes, field of view, and actor yaw rather than portrait normalization; melee impacts face from source to target. Readiness checks cover cached assets that do not deliver another load callback. Current asset mappings target Retail. Unverified clients and unavailable models skip the effect rather than drawing replacement spell shapes.

The UI simulator does not render these particle models or deliver every model animation callback. Its tests explicitly simulate asset completion to verify pooling, impacts, stance restoration, and cleanup. In Retail, check hunter shots returning to a ready stance, melee/caster combat stances, Frostbolt flight and impact, priest shields, healing, and level-up effects. Repeat in full-size and compact views, including reload and hide/show transitions; verify particle scale, direction, camera framing, and absence of lingering effects.

Map desaturation is restricted to land. Color restoration and hit testing use the same lossless region partition, so adjacent destinations cannot leave polygon gaps or overlap. The generator follows dark border strokes in the client artwork from sparse interior markers; biome colors and broad terrain shading do not define borders. Coarse land guides exclude parchment, while chroma classification follows the shoreline. Ownership propagates across inland water, while only land is desaturated. Excluded regions remain separate owners, rather than borrowing the nearest Classic destination. Masks retain one shared pixel scale and project each complete power-of-two texture, including its transparent padding. Mask UVs are not cropped. Native masks use explicit transparent-black clamping, and all channels are zero outside their shape; this avoids depending on simulator-specific cropped-mask projection.

Rebuild all 41 Retail destination masks with:

```sh
python3 scripts/prepare_map_masks.py --source-dir "$MAP_ART_SOURCE_DIR" --preview-dir "$MAP_REVIEW_DIR"
```

`MAP_ART_SOURCE_DIR` is an extracted `interface/worldmap` directory containing the `kalimdor` and `easternkingdoms` tile folders. The sibling `interface/adventuremap` directory supplies the unlabeled title tiles used by the UI when available. Keep source textures and review images outside the repository. `Assets/Maps/regions.json` contains the artwork identity, coarse shoreline guides, and interior markers, including non-destination regions. Generated profile-specific textures and the auditable owner field live in `Assets/Maps/retail`; `Compatibility/MapMasks.lua` supplies the runtime descriptors and hit-test rows. The review directory includes a region overview and a destination-by-destination contact sheet for each continent. Run StyLua on the generated Lua, then `python3 tests/map_masks.py`. The runtime checks the client flavor, continent ID, dimensions, and first artwork texture before applying a partition; unmatched artwork uses native hit testing without applying stale masks.

For geometry from a real client, run `/run WoWIdle.Client.ExportMapGeometry()` in game. This explicit developer action samples native `C_Map.GetMapInfoAtPosition` ownership at pixel centers over several frames. Close the export window to cancel. Copy the resulting JSON into a file outside the addon; it includes the build, profile, continent IDs, artwork dimensions, texture identity, and lossless region rows. Rebuild with `--client-data "$MAP_QUERY_EXPORT"`. Native owners take precedence; only Classic subdivisions absent from the native export retain artwork-derived boundaries. The generated `geometry.json` records those fallback destinations. No sampling occurs during normal play, and exports do not alter SavedVariables or send data.

For Forever, first update the supported simulator/client setup together. Supply Forever textures, exported queries, and a marker manifest with `profile` set to `forever`, then use `--regions "$FOREVER_MAP_MANIFEST" --lua-output "$FOREVER_MAP_LUA"`. Masks are written into that profile's asset directory. Load the resulting Lua descriptor alongside the Retail descriptor in the TOC when adding that client profile; the two profiles remain isolated. Interior markers and excluded regions still need review when the artwork or zone roster changes. Artwork-derived borders are estimates, while native exports can also contain merged regions; review both continents and all unlock bands after regeneration. This workflow does not establish live-client visual validation.
