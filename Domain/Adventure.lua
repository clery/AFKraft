local _, W = ...
local C, G = W.Content, W.Game

function G.AdventureXP(state, amount, kind, label)
    local progress, rules = state.adventure, C.adventure
    local ranks = math.floor((progress.xp + amount) / rules.xpPerRank)
    local essence = ranks * rules.essencePerRank
    progress.xp = (progress.xp + amount) % rules.xpPerRank
    progress.totalXP = progress.totalXP + amount
    progress.rank = progress.rank + ranks
    local source = progress.sources[kind] or { count = 0, xp = 0 }
    source.count, source.xp = source.count + 1, source.xp + amount
    progress.sources[kind] = source
    state.essence = state.essence + essence
    state.stats.essence = state.stats.essence + essence
    G.Log(state, "+" .. amount .. " Adventure XP · " .. label, true)
    if ranks > 0 then
        G.Emit(state, "levelup")
        G.Log(state, "Adventure rank " .. progress.rank .. " · +" .. essence .. " Essence")
    end
    return true, essence
end
