local _, W = ...
local Audio = {}
W.Audio = Audio

-- Blizzard SoundKitConstants: native adventure cues, resolved per client.
-- Missing kits remain silent on clients that do not expose them.
Audio.categories = {
    {
        key = "soundCombat",
        name = "Sounds: weapon hits",
        tip = "Sampled combat impacts, at most once every 1.2 seconds.",
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
        tip = "Boss entrances, victories, and party defeats.",
    },
    {
        key = "soundProgression",
        name = "Sounds: progression and unlocks",
        tip = "Hero levels, Adventure ranks, talents, training, recipes, destinations, and prestige.",
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
local pending, last = nil, {}
local quietUntil = -math.huge
local handle
local levelUpQuietUntil = -math.huge

function Audio.Stop()
    pending = nil
    if handle and StopSound then
        pcall(StopSound, handle)
    end
    handle = nil
    levelUpQuietUntil = -math.huge
end

local function audible(state)
    return state == W.state
        and not W.catchup
        and state.settings.soundEnabled
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
    elseif kind == "encounter" and not event.boss then
        return
    elseif kind == "victory" and event.boss then
        kind = "bossVictory"
    end
    local cue = cues[kind]
    local now = GetTime()
    if cue and state.settings[cue[1]] and now - (last[cue[1]] or -math.huge) >= cue[4] then
        if not pending or cue[3] > pending[3] then
            pending = cue
        end
    end
end

function Audio.Flush()
    -- Consume once per controller frame, independently of scene refreshes.
    -- Never retain a backlog to replay after reopening the window or catch-up.
    local cue = pending
    pending = nil
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
    local kit = type(cue[2]) == "number" and cue[2] or SOUNDKIT and SOUNDKIT[cue[2]]
    if type(kit) ~= "number" or kit <= 0 or not PlaySound then
        return
    end
    -- SFX respects the player's effects volume/mute; never force the Master channel.
    Audio.Stop()
    local ok, played, soundHandle = pcall(PlaySound, kit, "SFX", false)
    if ok and played then
        handle = soundHandle
        if kit == 888 then
            levelUpQuietUntil = now + 4
        end
        last[cue[1]] = now
        quietUntil = now + (cue[3] >= 4 and 2.5 or 0.65)
    end
end
