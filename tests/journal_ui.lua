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
    assertTrue(ui.journalBorder:IsShown())
    assertFalse(ui.journalClaim:IsEnabled())
    W.Game.RefreshJournal(s, W.Client.Now() + 172800)
    ui:Refresh()
    assertEquals(3, #ui.journalDays)
    click(ui.journalDays[1])
    assertEquals(1, ui.journalDay)
    for _, id in ipairs({ "achievements", "track", "contracts" }) do
        click(ui.journalTabs[id])
        assertEquals(id, ui.journalMode)
        assertEquals(ui.journalBorder:GetFrameLevel() - 1, ui.journalTabs[id]:GetFrameLevel())
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
    assertFalse(ui.journalBorder:IsShown())
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
        assertEquals(0.6, ui.journalProgress:GetParent():GetValue())
        assertEquals(510, ui.journalProgress:GetParent().clip:GetWidth())
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

test(
    "Journal textured bars clip their animation and stop when empty, complete or released",
    function()
        local W, s, ui = fixture()
        s.journal.xp = 120
        ui:Refresh()
        local bar = ui.journalProgress:GetParent()
        assertNotNil(ui.journalProgress:GetTexture())
        assertTrue(bar.clip:IsShown())
        assertEquals(850 * bar:GetValue(), bar.clip:GetWidth())
        local phase = bar.phase
        bar:GetScript("OnUpdate")(bar, 0.2)
        assertTrue(bar.phase ~= phase)
        ui:SetTab("adventure")
        assertFalse(bar:IsShown())
        ui:SetTab("journal")
        s.journal.xp = 0
        ui:Refresh()
        bar = ui.journalProgress:GetParent()
        assertFalse(bar.clip:IsShown())
        assertEquals(nil, bar:GetScript("OnUpdate"))
        for _, contract in ipairs(s.journal.days[1].ids) do
            s.journal.days[1].progress[contract] = W.Content.contractByID[contract].daily
        end
        ui:Refresh()
        for active in ui.panel._pool.journalBar:EnumerateActive() do
            if active:GetValue() == 1 then
                assertFalse(active.clip:IsShown())
                assertTrue(active.glowRemaining > 0)
                active:GetScript("OnUpdate")(active, 0.6)
                assertTrue(active.glow:GetAlpha() > 0)
                active:GetScript("OnUpdate")(active, 1.3)
                assertEquals(0, active.glow:GetAlpha())
                assertEquals(nil, active:GetScript("OnUpdate"))
            end
        end
    end
)

test("Journal preview follows upcoming, saved and bonus rewards and opens the track", function()
    local W, s, ui = fixture()
    assertEquals(W.Game.JournalReward(1, s, 1), ui.journalPreview.reward:GetText())
    click(ui.journalPreview)
    assertEquals("track", ui.journalMode)
    s.journal.pending[5] = 1
    ui:Refresh()
    assertEquals(W.Game.JournalReward(5, s, 1), ui.journalPreview.reward:GetText())
    assertTrue(ui.journalPreview.status:GetText():find("1", 1, true) ~= nil)
    s.journal.pending = {}
    s.journal.xp = W.Content.journal.ranks * W.Content.journal.xpPerRank
    s.journal.claimed = W.Content.journal.ranks
    ui:Refresh()
    assertEquals(W.L.JOURNAL_EXTRA_SUPPLIES, ui.journalPreview.reward:GetText())
    ui:SetTab("adventure")
    assertFalse(ui.journalPreview:IsShown())
end)

test("Completed contracts do not replay their glow on first display or redraw", function()
    local W, s, ui = fixture()
    local entry = s.journal.weekly
    local id = entry.ids[1]
    entry.progress[id] = W.Content.contractByID[id].weekly
    ui.journalObserved = nil
    ui:Refresh()
    for bar in ui.panel._pool.journalBar:EnumerateActive() do
        assertEquals(0, bar.glowRemaining)
    end
    ui:Refresh()
    for bar in ui.panel._pool.journalBar:EnumerateActive() do
        assertEquals(0, bar.glowRemaining)
    end
end)

test("Daily bonus stamps follow the selected set and stop at two completed contracts", function()
    local W, s, ui = fixture()
    ui.journalMode = "contracts"
    ui:Refresh()
    local entry = s.journal.days[ui.journalDay]
    for completed = 0, 3 do
        for index, id in ipairs(entry.ids) do
            entry.progress[id] = index <= completed and W.Content.contractByID[id].daily or 0
        end
        entry.bonus = completed >= 2
        ui:Refresh()
        assertEquals(completed >= 1, ui.journalBonusStamps[1]:IsShown())
        assertEquals(completed >= 2, ui.journalBonusStamps[2]:IsShown())
        assertEquals(entry.bonus, ui.journalBonusSeal:IsShown())
    end
    W.Game.RefreshJournal(s, W.Client.Now() + 86400)
    ui.journalDay = #s.journal.days
    ui:Refresh()
    assertFalse(ui.journalBonusStamps[1]:IsShown())
    assertFalse(ui.journalBonusStamps[2]:IsShown())
    assertFalse(ui.journalBonusSeal:IsShown())
    click(ui.journalDays[1])
    assertTrue(ui.journalBonusStamps[1]:IsShown())
    assertTrue(ui.journalBonusStamps[2]:IsShown())
    assertTrue(ui.journalBonusSeal:IsShown())
    ui:SetTab("adventure")
    assertFalse(ui.journalBonusSeal:IsShown())
end)

test("Completed Journal cards keep a text label as well as their colored progress", function()
    local W, s, ui = fixture()
    ui.journalMode = "contracts"
    ui:Refresh()
    local entry = s.journal.days[ui.journalDay]
    local id = entry.ids[1]
    entry.progress[id] = W.Content.contractByID[id].daily
    ui:Refresh()
    local function labels()
        local count = 0
        for _, region in ipairs({ ui.panel:GetRegions() }) do
            if region:IsShown() and region.GetText and region:GetText() == W.L.COMPLETE then
                count = count + 1
            end
        end
        return count
    end
    assertEquals(1, labels())
    ui:Refresh()
    assertEquals(1, labels())
    entry.progress[id] = 0
    ui:Refresh()
    assertEquals(0, labels())
    click(ui.journalTabs.achievements)
    local earned = 0
    for _ in pairs(s.journal.achievements) do
        earned = earned + 1
    end
    assertEquals(earned, labels())
end)

test("Reward milestones use larger framed medallions without changing scroll alignment", function()
    local _, _, ui = fixture()
    click(ui.journalTabs.track)
    for rank, node in ipairs(ui.journalTrack.nodes) do
        local milestone = rank % 5 == 0
        assertEquals(milestone and 96 or 82, node.icon:GetWidth())
        assertEquals(milestone, node.milestone ~= nil)
        if milestone then
            assertEquals(132, node.milestone:GetWidth())
            assertTrue(node.milestone:IsShown())
        end
    end
    click(ui.journalTabs.contracts)
    assertFalse(ui.journalTrack:IsShown())
end)
