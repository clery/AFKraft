if not test then
    return
end

test("Legacy collection talents purchase ranks and show active conditional drop chances", function()
    local W = WoWIdle
    W.Initialize()
    local G, ui, U = W.Game, W.UI, W.Widgets
    local s = G.New(W.Client.Now())
    G.AddHero(s, "WARRIOR")
    s.guide.dismissed = true
    W.state = s
    ui.frame:Show()
    ui.confirmPrestige = false
    ui:SetTab("legacy")
    assertFalse(ui.collectionTalentButtons.fieldcraft:IsEnabled())
    s.legacy = 12
    ui:Refresh()
    for _ = 1, 3 do
        assertTrue(ui.collectionTalentButtons.fieldcraft:IsEnabled())
        ui.collectionTalentButtons.fieldcraft:GetScript("OnClick")()
    end
    assertEquals(6, s.legacy)
    assertEquals(3, s.collectionTalents.fieldcraft)
    assertFalse(ui.collectionTalentButtons.fieldcraft:IsEnabled())
    ui.collectionTalentButtons.relicHunter:GetScript("OnClick")()
    assertEquals(5, s.legacy)
    local sourceProfile, tooltip = W.CollectionPanel.SourceProfile, U.Tooltip
    local details
    local ok, message = pcall(function()
        W.CollectionPanel.SourceProfile = function()
            return W.CollectionSources.profiles.forever16001
        end
        U.Tooltip = function(owner, title, text, ...)
            if title == G.CollectionItem(4701).name then
                details = text
            end
            return tooltip(owner, title, text, ...)
        end
        ui.collectionSelected = "redridgeOutriders"
        ui:SetTab("collections")
        assertTrue(details:find("8.00% chance", 1, true) ~= nil)
        assertTrue(details:find("base 5.00%", 1, true) ~= nil)
        assertTrue(details:find("Fieldcraft: Active (+60% of base)", 1, true) ~= nil)
        assertTrue(details:find("Relic Hunter: Inactive", 1, true) ~= nil)
    end)
    W.CollectionPanel.SourceProfile, U.Tooltip = sourceProfile, tooltip
    assertTrue(ok, message)
end)
