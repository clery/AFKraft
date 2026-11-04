local _, W = ...
local L = W.L
local A, G = W.Client, W.Game
local R = {}
W.GatheringRewards = R
local professions = {
    { id = 186, spell = 2575, name = L.MINING },
    { id = 182, spell = 2366, name = L.HERBALISM },
    { id = 393, spell = 8613, name = L.SKINNING },
}

local function readable(value)
    return not issecretvalue or not issecretvalue(value)
end

local function spellName(id)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(id)
    elseif GetSpellInfo then
        return GetSpellInfo(id)
    end
end

local function professionName(profession)
    if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
        local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(profession.id)
        if info and info.professionName then
            return info.professionName
        end
    end
    return profession.name
end

local function castProfession(id)
    local name = spellName(id)
    if not readable(name) or type(name) ~= "string" then
        return nil
    end
    for _, profession in ipairs(professions) do
        if id == profession.spell or name == spellName(profession.spell) then
            return profession
        end
    end
end

local function canSkillUp(color)
    if not color then
        return false
    end
    local r, g, b
    if color.GetRGB then
        r, g, b = color:GetRGB()
    else
        r, g, b = color.r, color.g, color.b
    end
    -- Orange, yellow, and green can grant skill; red, white, and gray cannot.
    return readable(r)
        and readable(g)
        and readable(b)
        and type(r) == "number"
        and type(g) == "number"
        and type(b) == "number"
        and g > 0.4
        and b < 0.55
        and (r > 0.7 or g > r + 0.1)
end

local function inspectTooltip(data)
    if not data or not data.lines then
        return nil
    end
    for _, line in ipairs(data.lines) do
        local text = line.leftText
        if readable(text) and type(text) == "string" then
            for _, profession in ipairs(professions) do
                local name = professionName(profession)
                local skin = profession.id == 393 and (SKINNABLE or L.SKINNABLE) or nil
                if text:find(name, 1, true) or (skin and text:find(skin, 1, true)) then
                    return {
                        profession = profession.id,
                        eligible = canSkillUp(line.leftColor),
                        time = A.Now(),
                        node = data.lines[1] and data.lines[1].leftText,
                    }
                end
            end
        end
    end
end

function R.Sample()
    if C_TooltipInfo then
        local data = C_TooltipInfo.GetWorldCursor and C_TooltipInfo.GetWorldCursor()
        local sample = inspectTooltip(data)
        if not sample and C_TooltipInfo.GetUnit then
            sample = inspectTooltip(C_TooltipInfo.GetUnit("mouseover"))
        end
        if sample then
            R.sample = sample
        end
        return sample
    end
end

local function grant(state, pending)
    if pending.success and (pending.eligible or pending.skillUp) then
        G.ActivityReward(
            state,
            "gather:" .. pending.guid,
            pending.profession.id == 393 and "skinning" or "gather",
            pending.profession.name .. L.GATHERING_SUFFIX
        )
    end
end

function R.Event(state, event, ...)
    if event == "CHAT_MSG_SKILL" then
        local message = ...
        local pending = R.pending
        if
            pending
            and A.Now() - pending.time <= 3
            and readable(message)
            and type(message) == "string"
            and message:find(professionName(pending.profession), 1, true)
        then
            pending.skillUp = true
            grant(state, pending)
        end
        return
    end
    local unit, arg2, arg3, arg4 = ...
    if not readable(unit) or unit ~= "player" then
        return
    end
    if event == "UNIT_SPELLCAST_SENT" then
        local guid, id = arg3, arg4
        if
            not readable(id)
            or not readable(guid)
            or type(id) ~= "number"
            or type(guid) ~= "string"
        then
            return
        end
        local profession = castProfession(id)
        if not profession then
            R.pending = nil
            return
        end
        local sample = R.Sample()
        if
            not sample
            and R.sample
            and readable(arg2)
            and readable(R.sample.node)
            and type(arg2) == "string"
            and arg2 ~= ""
            and arg2 == R.sample.node
        then
            sample = R.sample
        end
        R.pending = {
            guid = guid,
            profession = profession,
            time = A.Now(),
            eligible = sample
                and A.Now() - sample.time <= 1
                and sample.profession == profession.id
                and sample.eligible,
        }
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local guid, id = arg2, arg3
        if not readable(guid) or not readable(id) then
            return
        end
        local pending = R.pending
        if pending and pending.guid == guid and A.Now() - pending.time <= 30 then
            pending.success = true
            pending.time = A.Now()
            grant(state, pending)
        end
    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        if readable(arg2) and R.pending and R.pending.guid == arg2 then
            R.pending = nil
        end
    end
end
