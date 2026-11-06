# Embedded libraries

Loaded before addon modules in dependency order: LibStub, CallbackHandler, LibDataBroker, LibDBIcon, then the selected Ace3 components. Players do not need to install these separately. LibStub selects compatible shared versions when other addons embed them.

Upstream files are kept unmodified and excluded from addon formatting and diagnostics.

| Library | Source snapshot | License |
| --- | --- | --- |
| LibStub 2 | [Ace3 ac3d122](https://github.com/WoWUIDev/Ace3/tree/ac3d1225037e0dc74e025a72342c0f7824aae147/LibStub) | Public domain; notice in source |
| CallbackHandler 1.0 | [Ace3 ac3d122](https://github.com/WoWUIDev/Ace3/tree/ac3d1225037e0dc74e025a72342c0f7824aae147/CallbackHandler-1.0) | Ace3 BSD license in `Ace3-LICENSE.txt` |
| LibDataBroker 1.1 revision 4 | [tekkub 1a63ede](https://github.com/tekkub/libdatabroker-1-1/tree/1a63ede0248c11aa1ee415187c1f9c9489ce3e02) | Upstream source and README retained |
| LibDBIcon 1.0 revision 57 | [WowAce upstream](https://repos.wowace.com/wow/libdbicon-1-0/trunk/LibDBIcon-1.0/LibDBIcon-1.0.lua) | All Rights Reserved, Funkeh; distributed for embedding in addons |

AceAddon, AceEvent, AceConsole, AceTimer, AceDB, AceGUI, and AceConfig are embedded unmodified from [Ace3 ac3d122](https://github.com/WoWUIDev/Ace3/tree/ac3d1225037e0dc74e025a72342c0f7824aae147), covered by `Ace3-LICENSE.txt`. AceGUI and AceConfig load through their upstream XML manifests, including their widgets and configuration sublibraries.

LibDBIcon snapshot SHA-256: `cafa823dfb9f216eb476af4bcd2fad4c25c718f39b7565fa1c924dbebac41f91`.

The minimap launcher uses LibDataBroker callbacks for clicks and tooltips. LibDBIcon owns its button, drag handling, positioning, and visibility. Position, visibility, and lock settings live in `AFKraftDB.ui.minimap`; unread adventure notices remain addon presentation state.

AceAddon owns initialization/enabling, AceEvent owns event dispatch, AceConsole owns slash commands, and AceTimer owns activity sampling and slow UI refresh. The fixed-step combat/offline scheduler retains its elapsed-time accounting. AceDB stores account-wide preferences in `AFKraftPreferencesDB.global`, importing existing settings and UI state once from `AFKraftDB`. Existing gameplay save fields remain available as aliases. AceConfig/AceGUI generate the settings panel from an options table.

Blizzard object pools own management widget reuse. Native number formatting, dropdowns, tooltips, button templates, and animation groups supply presentation utilities. Gameplay rules, reward validation, save migrations, and bespoke scene layouts remain addon code.
