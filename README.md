# AFKraft : WoW Idle Game

**A little party. A long adventure.**

Your next dungeon group is still forming. Somewhere in Azeroth, your other party is already fighting.

AFKraft is an idle party RPG that lives inside World of Warcraft. Start with one hero, recruit companions, and build a company of five. Send them across Azeroth to fight, bring home loot, and take on tougher bosses while you play your own character.

Check in for a new weapon, rethink a talent build after a defeat, or pick the next zone to explore. Then let the party get back to work.

![AFKraft adventure panel showing the party battling in Elwynn Forest](https://github.com/clery/AFKraft/raw/refs/heads/main/Images/AdventurePanel.png)

## Build a party worth checking in on

Start with your character's identity and class, then discover more companions as you defeat milestone bosses. Choose from all nine original classes, mix roles, or double up on a favorite. Log in on an alt to let them take the place of a generated companion of the same class.

Battles play out automatically, but you decide how the party fights. Choose equipment, spend talent points, and set targeting and ability priorities. Each class has three talent trees, with free respecs so you can try a different approach when a boss stops you.

Heroes level to 60 through idle battles. Mastery adds permanent talent points as they keep winning challenging fights. Your whole account shares one adventure, so changing characters doesn't mean starting over.

![Rogue talent trees and combat priorities](https://github.com/clery/AFKraft/raw/refs/heads/main/Images/Talents.png)

## Pick the next stop

Explore 41 outdoor destinations across Kalimdor and the Eastern Kingdoms. Each has its own enemies, scenery, loot, and materials. Go looking for an upgrade, gather what the Forge needs, or return to a beaten boss for its trophy.

Use gold and materials to craft equipment, enhance a favorite piece, and work toward enchantments, titanforging, and lasting heirlooms. When the party loses, it falls back to safe farming. You can make a few changes and try the frontier again when you're ready.

Later, unlock routes to plan your travels and Commander boosts to help the party through a difficult fight.

## Your adventures help theirs

Questing, gathering, and fighting eligible enemies with your real WoW character earns Adventure XP. That becomes Essence, which buys permanent party improvements and unlocks Commander abilities.

Collections give you another reason to visit particular creatures and places. Find pieces through eligible kills, complete sets, and choose a set effect for your party.

The idle party also has its own progression through battles, loot, and crafting. Its levels, equipment, and currencies are separate from your WoW character's.

## Come back to something

Keep the adventure open in a full window, tuck it into compact mode, or close it while you play. The party keeps fighting while its window is hidden.

When you log back in, AFKraft calculates up to 24 hours of safe offline farming and applies the rewards automatically. New progression waits for you. There's time to look through the loot and decide what comes next.

Eventually, start a new chapter to earn Heritage and strengthen future runs. Rebuild with your recruited heroes, talents, Mastery, and other permanent investments intact. Farther along, Transcendence opens harder difficulty tiers and more lasting rewards. Both resets are your choice, with a preview of what you keep and what you lose.

![AFKraft compact mode alongside normal World of Warcraft gameplay](https://github.com/clery/AFKraft/raw/refs/heads/main/Images/CompactMode.png)

## Try the prototype

**AFKraft is an early playable prototype. Forever is the only planned release target.** Retail is currently used for development and simulator testing; there is no published Retail distribution.

Forever integration and live testing are still in progress, including maps, character visuals, reward detection, and save behavior. Collection hunting is disabled on Retail. Its Forever source profiles still need live testing, and progression pacing may change.

For a development copy:

1. Place the `WoWIdle` folder in your client's `Interface/AddOns` directory, with `WoWIdle.toc` directly inside it.
2. Enable the addon and log in. Restart WoW if it was running when you installed it.
3. Type `/afkcraft` to open the adventure and follow the starter guide. `/wowidle` and `/wi` also work.

Libraries are bundled. English, French, German, and Spanish are supported. You can change the language in **Settings > Language**, then use `/reload` to apply it.

## Follow development

See [what's still being worked on](HANDOFF.md) and the [changelog](CHANGELOG.md). For the details behind the game, read the [design](DESIGN.md), [item rules](Content/ITEMS.md), and [balance notes](BALANCE.md). Contributor setup and release checks are in [tooling](TOOLING.md), with separate guides for [architecture](ARCHITECTURE.md) and [maps](MAPS.md).

<!-- Reserved for the author's AI usage disclaimer. Add the final wording here. -->

## License and credits

AFKraft is **All Rights Reserved**. See [LICENSE](LICENSE).

Bundled libraries retain their own licenses and notices. See [library credits](Libs/README.md) and [landscape artwork credits](Assets/Backdrops/SOURCES.md) for the applicable terms and attribution.
