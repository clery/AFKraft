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

test("Monthly rewards scroll horizontally and reopen at the latest earned rank", function()
    local W, s, ui = fixture()
    s.journal.xp = 8 * W.Content.journal.xpPerRank
    s.journal.claimed = 3
    click(ui.journalTabs.contracts)
    click(ui.journalTabs.track)
    local track = ui.journalTrack
    assertEquals(20, #track.nodes)
    assertEquals(7 * 208, track.scroll:GetHorizontalScroll())
    assertEquals(W.L.AVAILABLE, track.nodes[8].status:GetText())
    assertEquals(W.L.COMPLETE, track.nodes[3].status:GetText())
    assertFalse(track.nodes[8].icon:IsDesaturated())
    assertTrue(track.nodes[9].icon:IsDesaturated())
    track.scroll:GetScript("OnMouseWheel")(track.scroll, 1)
    assertEquals(7 * 208, track.scroll:GetHorizontalScroll())
    track:GetScript("OnUpdate")(track, 0.08)
    assertTrue(track.scroll:GetHorizontalScroll() > 6 * 208)
    assertTrue(track.scroll:GetHorizontalScroll() < 7 * 208)
    ui:Refresh()
    track:GetScript("OnUpdate")(track, 0.3)
    assertEquals(6 * 208, track.scroll:GetHorizontalScroll())
    track.scroll:GetScript("OnMouseWheel")(track.scroll, 1)
    track:GetScript("OnUpdate")(track, 0.3)
    assertEquals(5 * 208, track.scroll:GetHorizontalScroll())
    track.scroll:GetScript("OnMouseWheel")(track.scroll, -1)
    track:GetScript("OnUpdate")(track, 0.3)
    assertEquals(6 * 208, track.scroll:GetHorizontalScroll())
    click(ui.journalTabs.contracts)
    assertFalse(track:IsShown())
    click(ui.journalTabs.track)
    assertEquals(7 * 208, track.scroll:GetHorizontalScroll())
    local function count(frame)
        local total = select("#", frame:GetRegions()) + 1
        for _, child in ipairs({ frame:GetChildren() }) do
            total = total + count(child)
        end
        return total
    end
    local before = count(track)
    for _ = 1, 10 do
        ui:Refresh()
    end
    assertEquals(before, count(track))
    ui:SetTab("adventure")
    assertFalse(track:IsShown())
    ui:SetTab("journal")
    assertEquals(7 * 208, track.scroll:GetHorizontalScroll())
    ui.frame:Hide()
    track.scroll:SetHorizontalScroll(0)
    ui.frame:Show()
    assertEquals(7 * 208, track.scroll:GetHorizontalScroll())
end)

test("Reward track aligns the first and final ranks and respects compact mode", function()
    local W, s, ui = fixture()
    ui.journalMode = "contracts"
    ui:Refresh()
    click(ui.journalTabs.track)
    local track = ui.journalTrack
    assertEquals(0, track.scroll:GetHorizontalScroll())
    assertFalse(track.left:IsShown())
    click(ui.journalTabs.contracts)
    s.journal.xp = W.Content.journal.ranks * W.Content.journal.xpPerRank
    click(ui.journalTabs.track)
    assertEquals(19 * 208, track.scroll:GetHorizontalScroll())
    assertFalse(track.right:IsShown())
    local _, _, _, offset = track.nodes[20]:GetPoint(1)
    assertEquals(offset, track.scroll:GetHorizontalScroll())
    s.ui.compact = true
    ui:ApplyMode()
    assertFalse(track:IsShown())
    s.ui.compact = false
    ui:ApplyMode()
    assertTrue(track:IsShown())
    assertEquals(19 * 208, track.scroll:GetHorizontalScroll())
end)

test(
    "Smooth reward scrolling accumulates bursts, reverses immediately and stops at boundaries",
    function()
        local W, s, ui = fixture()
        s.journal.xp = 8 * W.Content.journal.xpPerRank
        click(ui.journalTabs.contracts)
        click(ui.journalTabs.track)
        local track = ui.journalTrack
        assertEquals(nil, track.slider)
        local wheel = track.scroll:GetScript("OnMouseWheel")
        wheel(track.scroll, -1)
        wheel(track.scroll, -1)
        assertEquals(9 * 208, track.target)
        track:GetScript("OnUpdate")(track, 0.08)
        local before = track.scroll:GetHorizontalScroll()
        wheel(track.scroll, 1)
        track:GetScript("OnUpdate")(track, 0.04)
        assertTrue(track.scroll:GetHorizontalScroll() < before)
        wheel(track.scroll, 100)
        track:GetScript("OnUpdate")(track, 1)
        assertEquals(0, track.scroll:GetHorizontalScroll())
        assertEquals(nil, track:GetScript("OnUpdate"))
        wheel(track.scroll, -100)
        track:GetScript("OnUpdate")(track, 1)
        assertEquals(19 * 208, track.scroll:GetHorizontalScroll())
        assertEquals(nil, track:GetScript("OnUpdate"))
        wheel(track.scroll, 1)
        click(ui.journalTabs.contracts)
        assertEquals(nil, track:GetScript("OnUpdate"))
        click(ui.journalTabs.track)
        assertEquals(7 * 208, track.scroll:GetHorizontalScroll())
    end
)
