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

Combat spell effects use native M2 model files through PlayerModel, with FileDataIDs isolated in `Compatibility/SpellEffects.lua`. Spell IDs and SpellVisualKit IDs are different namespaces; do not substitute one for another. Spell models use an explicit side camera and a drawable one-pixel viewport during loading; readiness checks cover cached assets that do not deliver another load callback. Current asset mappings target Retail. Unverified clients and unavailable models skip the effect rather than drawing replacement spell shapes.

The UI simulator does not render these particle models or deliver every model animation callback. Its tests explicitly simulate asset completion to verify pooling, impacts, stance restoration, and cleanup. In Retail, check hunter shots returning to a ready stance, melee/caster combat stances, Frostbolt flight and impact, priest shields, healing, and level-up effects. Repeat in full-size and compact views, including reload and hide/show transitions; verify particle scale, direction, camera framing, and absence of lingering effects.

Map desaturation is restricted to land, with sea, parchment and decorations kept in color. Retail masks follow the high-resolution continent artwork; the small fallback hit-test polygons are not used as visual masks. Original map colors are restored inside unlocked destinations. Rebuild the masks and their bounds with `python3 scripts/prepare_map_masks.py --source-dir "$MAP_ART_SOURCE_DIR"`, pointing to an extracted `interface/worldmap` directory containing the `kalimdor` and `easternkingdoms` tile folders. Keep these source textures outside the repository. The editable artwork-space traces live in `Assets/Maps/regions.json`; generated bounds live in `Compatibility/MapMasks.lua`. Run StyLua on the generated Lua bounds, then `python3 tests/map_masks.py` for shoreline and zone-edge regressions. Destination access still uses the shared frontier rules.
