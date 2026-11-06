if not test then
    return
end
local function click(control)
    assertNotNil(control)
    assertTrue(control:IsEnabled())
    control:GetScript("OnClick")(control)
end
local function fixture()
    local W = AFKraft
    W.Initialize()
    local s = W.Game.New(W.Client.Now())
    W.Game.AddHero(s, "WARRIOR")
    s.guide.dismissed = true
    W.state = s
    local ui = W.UI
    ui.frame:Show()
    ui:SetTab("journal")
    return W, s, ui
end

test("Journal navigation, daily catch-up, tabs and frame pools stay interactive", function()
    local W, s, ui = fixture()
    assertEquals("journal", s.ui.tab)
    assertFalse(ui.journalClaim:IsEnabled())
    W.Game.RefreshJournal(s, W.Client.Now() + 172800)
    ui:Refresh()
    assertEquals(3, #ui.journalDays)
    click(ui.journalDays[1])
    assertEquals(1, ui.journalDay)
    for _, id in ipairs({ "achievements", "track", "contracts" }) do
        click(ui.journalTabs[id])
        assertEquals(id, ui.journalMode)
    end
    local counts = {}
    for _, pool in pairs(ui.panel._pool) do
        counts[pool] = pool:GetNumActive()
    end
    local children = ui.panel:GetNumChildren()
    ui:Refresh()
    assertEquals(children, ui.panel:GetNumChildren())
    for _, pool in pairs(ui.panel._pool) do
        assertEquals(counts[pool], pool:GetNumActive())
    end
    ui:SetTab("adventure")
    assertEquals("adventure", s.ui.tab)
end)

test("Journal activity refreshes progress and reward claims update their controls", function()
    local W, s, ui = fixture()
    local previous = ui.panelFeature
    W.Game.ActivityReward(s, "journal-ui:quest", "quest", "Quest")
    ui:Refresh(false)
    assertTrue(ui.panelFeature ~= previous)
    assertEquals(1, s.journal.days[1].progress.quest)
    click(ui.journalTabs.track)
    s.journal.xp = 5 * W.Content.journal.xpPerRank
    ui:Refresh()
    assertTrue(ui.journalClaim:IsEnabled())
    for _ = 1, 5 do
        click(ui.journalClaim)
    end
    assertEquals(5, s.journal.claimed)
    assertEquals(5, s.journal.title)
    assertFalse(ui.journalClaim:IsEnabled())
    ui:SetTab("adventure")
    assertTrue(ui.section:GetText():find(W.L.JOURNAL_TITLE_5, 1, true) ~= nil)
    s.ui.compact = true
    ui:ApplyMode()
    s.ui.compact = false
    ui:ApplyMode()
    ui:SetTab("journal")
    assertNotNil(ui.journalTitle)
end)

test("Journal celebrations use the existing bounded toast queue", function()
    local W, s = fixture()
    W.Notifications.Clear()
    s.settings.rewardToasts = true
    W.Game.Emit(s, "journal", { heading = W.L.JOURNAL_ACHIEVEMENT, title = W.L.JOURNAL_A_SERVICE })
    assertEquals(1, #W.Notifications.queue)
    assertEquals("journal", W.Notifications.queue[1].tab)
    s.settings.rewardToasts = false
    W.Game.Emit(s, "journal", { heading = W.L.JOURNAL_ACHIEVEMENT, title = W.L.JOURNAL_A_VETERAN })
    assertEquals(1, #W.Notifications.queue)
    W.Notifications.Clear()
end)

test(
    "Monthly Journal retains selectable titles and saved choice rewards across reset and prestige",
    function()
        local W, s, ui = fixture()
        local G, originalNow = W.Game, W.Client.Now
        local _, resetTime = G.JournalCalendar(originalNow())
        local ok, message = pcall(function()
            s.journal.xp = 5 * W.Content.journal.xpPerRank
            s.journal.claimed = 3
            W.Client.Now = function()
                return resetTime
            end
            ui.journalMode = "track"
            ui:Refresh(false)
            assertEquals(0, G.JournalRank(s))
            assertEquals(2, G.JournalRewardsWaiting(s))
            assertTrue(ui.journalClaim:IsEnabled())
            assertTrue(ui.journalClaim.text:GetText():find("2", 1, true) ~= nil)
            assertTrue(G.SetJournalTitle(s, 5))
            click(ui.journalClaim)
            assertEquals(0, s.journal.claimed)
            assertEquals(1, G.JournalRewardsWaiting(s))
            assertTrue(G.ResetAdventure(s, false))
            ui:Refresh()
            click(ui.journalClaim)
            assertEquals(0, G.JournalRewardsWaiting(s))
            assertEquals(5, s.journal.title)
            assertFalse(ui.journalClaim:IsEnabled())
            assertTrue(s.recipes[ui.journalSlot])
        end)
        W.Client.Now = originalNow
        assertTrue(ok, message)
    end
)

test("Journal bonus progress remains visible after pooled redraws", function()
    local W, s, ui = fixture()
    s.journal.xp = W.Content.journal.ranks * W.Content.journal.xpPerRank
    s.journal.bonusXP = 120
    for _ = 1, 3 do
        ui:Refresh()
        assertEquals("ARTWORK", ui.journalProgress:GetDrawLayer())
        assertEquals(510, ui.journalProgress:GetWidth())
    end
end)
