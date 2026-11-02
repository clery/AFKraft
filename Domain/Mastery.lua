local _, W = ...
local C, G = W.Content, W.Game
local min, max, floor = math.min, math.max, math.floor

local function whole(value)
    return type(value) == "number" and value >= 0 and value < math.huge and value == floor(value)
end

function G.MasteryCost(rank)
    return C.mastery.baseXP + rank * C.mastery.xpPerRank
end

function G.MasteryProgress(hero)
    local mastery = hero.mastery
    if mastery == nil then
        mastery = { rank = 0, xp = 0, frontier = 0 }
    elseif
        type(mastery) ~= "table"
        or not whole(mastery.rank)
        or not whole(mastery.xp)
        or not whole(mastery.frontier)
        or G.MasteryCost(mastery.rank) >= math.huge
        or mastery.xp >= G.MasteryCost(mastery.rank)
    then
        return nil, "The saved Mastery progression is invalid. Your adventure has not been reset."
    end
    hero.mastery = mastery
    return mastery
end

function G.MasteryUnlocked(hero)
    local progress = G.TalentProgress(hero)
    return progress and progress.bestLevel >= C.mastery.unlockLevel or false
end

-- Victory XP feeds a separate, persistent track even at the character level cap.
-- Its encounter frontier survives prestige so easier runs cannot farm Mastery.
function G.RewardMastery(hero, encounterLevel, experience, boss)
    if not whole(encounterLevel) or encounterLevel < 1 or not whole(experience) then
        return 0, 0
    end
    local mastery = G.MasteryProgress(hero)
    local progress = G.TalentProgress(hero)
    if not mastery or not progress then
        return 0, 0
    end
    local eligible = encounterLevel >= mastery.frontier
    mastery.frontier = max(mastery.frontier, encounterLevel)
    if not eligible or not G.MasteryUnlocked(hero) or progress.earned >= #G.TalentList(hero) then
        return 0, 0
    end
    local gained = experience * (boss and C.mastery.bossMultiplier or 1)
    if gained >= math.huge then
        return 0, 0
    end
    local xp, ranks = mastery.xp + gained, 0
    local limit = #G.TalentList(hero)
    while progress.earned < limit and xp >= G.MasteryCost(mastery.rank) do
        xp = xp - G.MasteryCost(mastery.rank)
        mastery.rank = mastery.rank + 1
        progress.earned = progress.earned + 1
        ranks = ranks + 1
    end
    mastery.xp = min(xp, G.MasteryCost(mastery.rank) - 1)
    return gained, ranks
end
