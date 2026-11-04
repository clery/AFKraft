if not test then
    return
end

local function setup()
    local W = WoWIdle
    W.Initialize()
    local state = W.Game.New(W.Client.Now())
    W.Game.AddHero(state, "WARRIOR")
    state.guide.dismissed = true
    W.state = state
    W.UI.selected, W.UI.recruiting, W.UI.disenchantOpen = 1, false, false
    W.UI.frame:Show()
    return W, state, W.UI
end

test(
    "Adventure tooltip displays the configured XP costs and fractional activity rewards",
    function()
        local W = setup()
        local parent = CreateFrame("Frame", nil, UIParent)
        local bar = W.AdventureBar.Create(parent, 0, 0, 400)
        local rules = W.Content.adventure
        local previousXP, previousEssence = rules.xpPerRank, rules.essencePerRank
        local ok, message = pcall(function()
            rules.xpPerRank, rules.essencePerRank = 125, 75
            bar.frame:GetScript("OnEnter")(bar.frame)
            local text = {}
            for _, region in ipairs({ GameTooltip:GetRegions() }) do
                if region:GetObjectType() == "FontString" then
                    text[#text + 1] = region:GetText() or ""
                end
            end
            local details = table.concat(text, "\n")
            assert(details:find("125 Adventure XP = 75 Essence", 1, true))
            for _, id in ipairs(W.Content.activityOrder) do
                local reward = W.Content.activityRewards[id]
                local expected = reward.name .. " · " .. reward.xp .. " XP"
                assert(details:find(expected, 1, true), "Missing reward: " .. expected)
            end
        end)
        rules.xpPerRank, rules.essencePerRank = previousXP, previousEssence
        GameTooltip:Hide()
        parent:Hide()
        assert(ok, message)
    end
)

test("Mastery help uses the selected difficulty frontier and actual next-rank price", function()
    local W, state, ui = setup()
    local hero = state.heroes[1]
    hero.level = 20
    hero.mastery = { rank = 9, xp = 0, frontier = 60, frontiers = { [0] = 60, [2] = 23 } }
    state.tier = 2
    local tooltip, details = W.Widgets.Tooltip, nil
    W.Widgets.Tooltip = function(owner, title, text, ...)
        if title == "Permanent Mastery" then
            details = text
        end
        return tooltip(owner, title, text, ...)
    end
    local ok, message = pcall(function()
        ui:SetTab("talents")
        assert(type(details) == "string")
        assert(details:find("Tier 2: earn XP from victories at encounter level 23+", 1, true))
        assert(details:find("Next rank: " .. W.Game.MasteryCost(9) .. " XP", 1, true))
        hero.level, hero.mastery.rank = 60, 24
        local progress = assert(W.Game.TalentProgress(hero))
        progress.earned = #W.Game.TalentList(hero)
        ui:Refresh()
        assert(type(details) == "string")
        assert(details:find("All talent points earned.", 1, true))
        assert(not details:find("Next rank:", 1, true))
    end)
    W.Widgets.Tooltip = tooltip
    assert(ok, message)
end)

test(
    "Unavailable collection hunts explain the client restriction without advertising a chance",
    function()
        local W, _, ui = setup()
        local tooltip, profile = W.Widgets.Tooltip, W.CollectionSources.ActiveProfile
        local flavor = W.Client.flavor
        W.Client.flavor = "forever"
        local details
        W.CollectionSources.ActiveProfile = function()
            return nil
        end
        W.Widgets.Tooltip = function(owner, title, text, ...)
            if title == W.Game.CollectionItem(4701).name then
                details = text
            end
            return tooltip(owner, title, text, ...)
        end
        local ok, message = pcall(function()
            assert(W.CollectionPanel.SourceProfile("outdoor") == nil)
            ui.collectionSelected = "redridgeOutriders"
            ui:SetTab("collections")
            assert(type(details) == "string")
            assert(details:find("Hunting unavailable on this client build", 1, true))
            assert(not details:find("chance", 1, true))
        end)
        W.Widgets.Tooltip, W.CollectionSources.ActiveProfile = tooltip, profile
        W.Client.flavor = flavor
        assert(ok, message)
    end
)

test("Equipment help omits zero attributes and distinguishes an empty outfit", function()
    local W, state, ui = setup()
    local tooltip, details = W.Widgets.Tooltip, nil
    W.Widgets.Tooltip = function(owner, title, text, ...)
        if title == "Permanent party development · Equipment stats" then
            details = text
        end
        return tooltip(owner, title, text, ...)
    end
    local ok, message = pcall(function()
        ui:SetTab("party")
        assert(type(details) == "string")
        assert(details:find("No equipment bonuses.", 1, true))
        state.heroes[1].gear[1] = assert(W.Game.CraftItem(state.heroes[1], 1, false, state))
        ui:Refresh()
        assert(type(details) == "string")
        assert(not details:find("No equipment bonuses.", 1, true))
        assert(not details:find(": 0%.0"))
    end)
    W.Widgets.Tooltip = tooltip
    assert(ok, message)
end)
