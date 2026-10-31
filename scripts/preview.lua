-- Optional visual fixture. Not loaded by the addon or written into a player save.
local W = WoWIdle
W.Initialize()
local s = W.Game.New(W.Client.Now())
local names = { "Arden", "Liora", "Caelis", "Briar", "Mira" }
for i, id in ipairs({ "WARRIOR", "PRIEST", "MAGE", "HUNTER", "DRUID" }) do
    W.Game.AddHero(s, id)
    local h = s.heroes[i]
    h.name = names[i]
    h.level = 6
    h.rank = 1
    h.gear[1] = W.Game.Item(s, 1, 5, 3)
    h.talents[i == 1 and "guard" or i == 2 and "sustain" or "cleave"] = true
end
s.essence = 184
s.gold = 672
s.legacy = 2
s.materials = { timber = 28, hide = 19, ore = 34, relic = 12 }
s.safe.elwynn = 12
s.stage = 13
s.runBest = 5
s.best = 5
W.Game.Loot(s, W.Game.Item(s, 2, 6, 3))
W.Game.Loot(s, W.Game.Item(s, 3, 5, 2))
W.state = s
W.Game.StartBattle(s)
W.UI.frame:Show()
W.UI:ApplyMode()
W.UI:Refresh()
