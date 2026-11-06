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

## Source checks

From the repository root, run:

```sh
lua scripts/test.lua
wow-sim-retail --addons-path "$ADDON_ROOT" --no-saved-vars run-tests AFKraft
stylua --check .
lua-language-server --check=. --checklevel=Hint --logpath="$LUALS_LOG_DIR" --metapath="$LUALS_META_DIR"
```

Use an isolated addon root and keep diagnostic output outside the repository. LuaLS must report zero diagnostics, including hints. Balance scenarios and their assumptions are listed in [BALANCE.md](BALANCE.md); recorded results are not live playtest evidence.

## Visual checks

Check fullscreen, expanded, and compact sizes; text clipping; map tiles; tab changes; party composition; locked-window access; and offline progress summaries. Repeat checks after UI changes. Do not commit game assets or environment logs.

## Native combat visuals

Combat spell effects use native M2 model files through ModelScene actors, with FileDataIDs isolated in `Compatibility/SpellEffects.lua`. Spell IDs and SpellVisualKit IDs are different namespaces; do not substitute one for another. Spell models use an explicit side camera and a drawable one-pixel viewport during loading. The final viewport has triple padding with a proportionally increased camera distance to preserve apparent size, and is sized before camera setup. Combat effects use explicit world-space camera axes, field of view, and actor yaw rather than portrait normalization; melee impacts face from source to target. Readiness checks cover cached assets that do not deliver another load callback. Current asset mappings target Retail. Unverified clients and unavailable models skip the effect rather than drawing replacement spell shapes.

The UI simulator does not render these particle models or deliver every model animation callback. Its tests explicitly simulate asset completion to verify pooling, impacts, stance restoration, and cleanup. In Retail, check hunter shots returning to a ready stance, melee/caster combat stances, Frostbolt flight and impact, priest shields, healing, and level-up effects. Repeat in full-size and compact views, including reload and hide/show transitions; verify particle scale, direction, camera framing, and absence of lingering effects.

## Continent maps

The map generator builds shared color and hit geometry from client artwork, with optional native ownership exports. Rebuild current Retail data with Python 3 and Pillow:

```sh
python3 scripts/prepare_map_masks.py --source-dir "$MAP_ART_SOURCE_DIR" --preview-dir "$MAP_REVIEW_DIR"
stylua Compatibility/MapMasks.lua
python3 tests/map_masks.py
```

Keep extracted textures, exported native queries, and review images outside the repository. Inspect the ownership overview, visible-mask sheets, and clickable-region sheets for both continents; color-only previews do not reveal oversized invisible hit areas. Restart the actual client after updating textures.

See [the map maintenance and porting guide](MAPS.md) for schemas, coordinate conventions, native exports, boundary corrections, rendering constraints, tests, and complete Forever/new-continent checklists. That guide identifies the remaining two-continent integration points; generation alone does not register a new continent in the runtime or UI.

## Packaging

Python 3.9+ builds a Forever ZIP using only the standard library:

```sh
python3 tests/packaging.py
python3 scripts/package.py --version 0.2.0
```

The result is `artifacts/AFKcraft-0.2.0-forever.zip`, containing a single
`AFKraft/` folder. Extract it into the client's `Interface/AddOns` directory.
The version defaults to the source TOC version; `--output` selects another output
directory. The packaged TOC declares Forever interface `16001` and retains the
source load order and SavedVariables. The source TOC keeps both client versions
for development. Shared code, compatibility profiles and current artwork remain
available for a possible Retail release; there is no Retail packaging target yet.

The builder follows TOC/XML includes, includes all artwork and required library
notices, and excludes development tools, tests and editor configuration. Bundled
libraries are used as checked in; packaging downloads nothing. CI runs the Lua
suite and packaging checks and uploads a Forever build artifact. It does not tag,
publish a GitHub release, or upload to addon services.

Before any release, update `CHANGELOG.md` and the source TOC version, review the
archive, and complete Forever integration. In the actual Forever client, test a
fresh install and an existing save, login/reload, both saved-variable stores,
map selection, character models, activity rewards, and all window sizes. Retail
simulator checks do not replace these checks. A future Retail distribution needs
its own validated interface version, package target and client checks.
