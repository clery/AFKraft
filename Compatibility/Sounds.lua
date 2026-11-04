local _, W = ...
local Audio = {}
W.Audio = Audio

-- Blizzard SoundKitConstants: native adventure cues, resolved per client.
-- Missing kits remain silent on clients that do not expose them.
Audio.categories = {
    {
        key = "soundCombat",
        name = "Sounds: combat and voices",
        tip = "Weapon impacts, attack voices and wound sounds.",
    },
    {
        key = "soundSpells",
        name = "Sounds: abilities and healing",
        tip = "Special attacks, healing, and defensive abilities.",
    },
    {
        key = "soundDeaths",
        name = "Sounds: deaths",
        tip = "Enemies falling and companions being defeated.",
    },
    {
        key = "soundEncounters",
        name = "Sounds: encounters",
        tip = "Creature entrance calls, victories, and party defeats.",
    },
    {
        key = "soundProgression",
        name = "Sounds: progression and unlocks",
        tip = "Hero levels, Adventure ranks, talents, recipes, destinations and resets.",
    },
    {
        key = "soundEquipment",
        name = "Sounds: equipment and loot",
        tip = "Crafting, upgrading, equipping, and rare loot.",
    },
    {
        key = "soundTravel",
        name = "Sounds: travel and recruitment",
        tip = "Changing destinations and recruiting companions.",
    },
}

-- category, client sound-kit constant, priority, category cooldown (seconds).
local cues = {
    hit = { "soundCombat", "UI_ADVENTURES_DAMAGE_SWEETENER_MEDIUM", 1, 1.2 },
    special = { "soundSpells", "UI_ADVENTURES_DAMAGE_SWEETENER_LARGE", 2, 1.8 },
    heal = { "soundSpells", "UI_ADVENTURES_HEAL_FOLLOWER", 2, 1.8 },
    defense = { "soundSpells", "UI_ADVENTURES_DEFENSIVE_SWEETENER", 2, 1.8 },
    enemyDeath = { "soundDeaths", "UI_ADVENTURES_DEATH_ENEMY", 3, 1.5 },
    heroDeath = { "soundDeaths", "UI_ADVENTURES_DEATH_FRIENDLY", 3, 1.5 },
    encounter = { "soundEncounters", "UI_PET_BATTLE_START", 3, 4 },
    victory = { "soundEncounters", "IG_QUEST_LIST_COMPLETE", 3, 8 },
    bossVictory = { "soundEncounters", "UI_ADVENTURES_ADVENTURE_SUCCESS_COMPLETE", 4, 8 },
    defeat = { "soundEncounters", "UI_ADVENTURES_ADVENTURE_FAILURE_COMPLETE", 4, 8 },
    -- Native character level-up fanfare (SoundKit 888, sound/spells/levelup.ogg).
    levelup = { "soundProgression", 888, 5, 4 },
    unlock = { "soundProgression", "UI_GARRISON_FOLLOWER_LEARN_TRAIT", 5, 2 },
    train = { "soundProgression", "UI_GARRISON_FOLLOWER_LEARN_TRAIT", 5, 2 },
    prestige = { "soundProgression", "UI_SCENARIO_ENDING", 6, 2 },
    equip = { "soundEquipment", "IG_ABILITY_ICON_DROP", 3, 0.5 },
    craft = { "soundEquipment", "JEWEL_CRAFTING_FINALIZE", 3, 0.5 },
    upgrade = { "soundEquipment", "ITEM_REPAIR", 3, 0.5 },
    loot = { "soundEquipment", "LOOT_WINDOW_COIN_SOUND", 2, 4 },
    travel = { "soundTravel", "IG_MINIMAP_OPEN", 3, 1 },
    recruit = { "soundTravel", "IG_PLAYER_INVITE", 3, 1 },
}
-- Native SoundKit IDs (not FileDataIDs). Each kit supplies its own variations.
-- Profiles follow the NPC appearances in ModelAssets, rather than display names.
-- attack, death, aggro, wound; omitted entries retain the ordinary cue.
local voices = {
    wolf = { 391, 394, 390, 392 },
    kobold = { 312, 314, 694, 315 },
    gnoll = { 306, 308, 1015, 309 },
    boar = { 380, 383, 379, 381 },
    quillboar = { 1176, 1179, 1181, 1177 },
    thief = { 322, 324, nil, 325 },
    harvest = { 2087, 2518, 2092, 2088 },
    air = { nil, 3787, 3789 },
    cat = { 643, 646, nil, 644 },
    centaur = { 1040, 1043, 1044, 1041 },
    orc = { 1319, 1322, 1346, 1320 },
    whelp = { 429, 432, 428, 430 },
    furbolg = { 355, 357, nil, 358 },
    ancient = { 1494, 3375, 1498, 1495 },
    skeleton = { 335, 337, 1016, 338 },
    worgen = { 558, 441, 437, 439 },
    troll = { 1029, 1032, 1034, 1030 },
    goblin = { 1409, 1413, nil, 1410 },
    vulture = { 442, 444, 447, 445 },
    ogre = { 397, 400, 396, 398 },
    yeti = { 1239, 1242, 1243, 1240 },
}
local creatureVoices = {
    [299] = "wolf",
    [6] = "kobold",
    [448] = "gnoll",
    [3098] = "boar",
    [3111] = "quillboar",
    [3100] = "boar",
    [38] = "thief",
    [114] = "harvest",
    [832] = "air",
    [3425] = "cat",
    [3272] = "centaur",
    [3261] = "quillboar",
    [4064] = "orc",
    [446] = "gnoll",
    [441] = "whelp",
    [2033] = "cat",
    [3749] = "furbolg",
    [3919] = "ancient",
    [48] = "skeleton",
    [898] = "worgen",
    [215] = "thief",
    [2102] = "orc",
    [687] = "cat",
    [595] = "troll",
    [675] = "goblin",
    [4640] = "centaur",
    [4695] = "vulture",
    [4663] = "orc",
    [5618] = "thief",
    [5646] = "troll",
    [5474] = "ogre",
    [7431] = "cat",
    [7439] = "furbolg",
    [7459] = "yeti",
}
local characterVoices = {
    human_male = { 2941, 2944, nil, 2942 },
    human_female = { 2937, 2940, nil, 2938 },
    orc_male = { 1319, 1322, nil, 1320 },
    orc_female = { 209, 213, nil, 211 },
    dwarf_male = { 2929, 2932, nil, 2930 },
    dwarf_female = { 2925, 2928, nil, 2926 },
    nightelf_male = { 2956, 2959, nil, 2957 },
    nightelf_female = { 2933, 2936, nil, 2934 },
    undead_male = { 1315, 1318, nil, 1316 },
    undead_female = { 1361, 1364, nil, 1362 },
    tauren_male = { 1353, 1356, nil, 1354 },
    tauren_female = { 225, 229, nil, 227 },
}

local function actorVoice(state, enemy, index, action)
    if not index then
        return
    end
    if enemy then
        local unit = state.battle and state.battle.enemies[index]
        local spec = unit and W.Client and W.Client.ModelSpec(nil, state.zone, unit.name)
        local profile = spec and voices[creatureVoices[spec.creatureID]]
        return profile and (profile[action] or action == 3 and profile[1])
    end
    local hero = state.heroes[index]
    if not hero then
        return
    end
    local appearance = hero.appearance
    if hero.guid and W.Client and hero.guid == W.Client.Identity().guid then
        -- The player's model uses their live appearance, not the recruit preset.
        local _, race
        if UnitRace then
            _, race = UnitRace("player")
        end
        race = race and race:lower()
        if race == "scourge" then
            race = "undead"
        end
        local sex = UnitSex and UnitSex("player")
        appearance = race and (sex == 2 or sex == 3) and race .. (sex == 2 and "_male" or "_female")
            or nil
    end
    local profile = characterVoices[appearance]
    return profile and profile[action]
end

local pending, last = nil, {}
local pendingHits = {}
local quietUntil = -math.huge
local handles = {}
local levelUpQuietUntil = -math.huge

function Audio.Stop()
    pending = nil
    pendingHits = {}
    for i = #handles, 1, -1 do
        if StopSound then
            pcall(StopSound, handles[i])
        end
        handles[i] = nil
    end
    levelUpQuietUntil = -math.huge
end

local function audible(state)
    return state == W.state
        and not W.catchup
        and state.settings.soundEnabled
        and (state.ui.compact or (state.ui.tab or "adventure") == "adventure")
        and W.UI
        and W.UI.frame:IsShown()
end

function W.OnGameEvent(state, event)
    if not audible(state) then
        return
    end
    if event.kind == "heal" and (event.amount or 0) <= 0 then
        return
    end
    local kind = event.kind
    if kind == "cast" then
        kind = event.action == "special" and "special" or nil
    elseif kind == "death" then
        kind = event.enemy and "enemyDeath" or "heroDeath"
    elseif kind == "victory" and event.boss then
        kind = "bossVictory"
    end
    local cue = cues[kind]
    local now = GetTime()
    local side = kind == "hit" and (event.enemy and "heroHit" or "mobHit") or nil
    local cooldown = side or cue and cue[1]
    if cue and state.settings[cue[1]] and now - (last[cooldown] or -math.huge) >= cue[4] then
        if side and not pendingHits[side] or not side and (not pending or cue[3] > pending[3]) then
            local kit, voice, wound
            if kind == "hit" then
                voice = actorVoice(state, not event.enemy, event.source, 1)
                local targets = state.battle
                    and (event.enemy and state.battle.enemies or state.battle.heroes)
                local target = targets and targets[event.target]
                if target and target.hp > 0 then
                    wound = actorVoice(state, event.enemy, event.target, 4)
                end
                if not event.enemy then
                    -- Creature attacks carry their own bite/claw/exertion sound.
                    kit, voice = voice, nil
                elseif voice then
                    local hero = state.heroes[event.source]
                    local melee = hero
                        and (
                            hero.class == "WARRIOR"
                            or hero.class == "PALADIN"
                            or hero.class == "ROGUE"
                            or hero.class == "SHAMAN"
                            or hero.class == "DRUID"
                        )
                    -- MediumWeaponNormal complements melee exertions.
                    if melee then
                        kit = 235
                    else
                        kit, voice = voice, nil
                    end
                end
            elseif kind == "special" then
                voice = actorVoice(state, false, event.source, 1)
            elseif kind == "enemyDeath" or kind == "heroDeath" then
                kit = actorVoice(state, event.enemy, event.target, 2)
            elseif kind == "encounter" then
                kit = actorVoice(state, true, 1, 3)
                if not kit and not event.boss then
                    return
                end
            end
            local resolved = { cue[1], kit or cue[2], cue[3], cue[4], voice, wound, cooldown }
            if side then
                pendingHits[side] = resolved
            else
                pending = resolved
            end
        end
    end
end

function Audio.Flush()
    -- Consume once per controller frame, independently of scene refreshes.
    -- Never retain a backlog to replay after reopening the window or catch-up.
    local cue = pending
    local heroHit, mobHit = pendingHits.heroHit, pendingHits.mobHit
    pending = nil
    pendingHits = {}
    local batch = cue and { cue } or { heroHit or mobHit }
    if not cue and heroHit and mobHit then
        batch[2] = mobHit
    end
    cue = batch[1]
    if not audible(W.state) then
        Audio.Stop()
        return
    end
    if not cue or not W.state.settings[cue[1]] then
        return
    end
    local now = GetTime()
    -- Let the fanfare ring out without an ordinary hit, loot or unlock cue
    -- stopping it on the next controller frame. Prestige can still supersede it.
    if now < levelUpQuietUntil and cue[3] <= 5 then
        return
    end
    if cue[3] < 4 and now < quietUntil then
        return
    end
    -- Stop the previous sample once; both sides of this exchange may play together.
    Audio.Stop()
    for _, sample in ipairs(batch) do
        local kit = type(sample[2]) == "number" and sample[2] or SOUNDKIT and SOUNDKIT[sample[2]]
        local playedAny = false
        for slot = 1, 3 do
            local id
            if slot == 1 then
                id = kit
            else
                id = sample[slot + 3]
            end
            if type(id) == "number" and id > 0 and PlaySound then
                -- SFX respects the player's effects volume/mute.
                local ok, played, soundHandle = pcall(PlaySound, id, "SFX", false)
                if ok and played then
                    playedAny = true
                    if soundHandle then
                        handles[#handles + 1] = soundHandle
                    end
                end
            end
        end
        if playedAny then
            if kit == 888 then
                levelUpQuietUntil = now + 4
            end
            last[sample[7]] = now
            quietUntil = now
                + (sample[3] >= 4 and 2.5 or sample[1] == "soundEncounters" and 1.8 or 0.65)
        end
    end
end
