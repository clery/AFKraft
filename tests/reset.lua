if not test then
    return
end

test(
    "Full reset replaces account progress and discards pending catch-up without rebuilding UI",
    function()
        local W = AFKraft
        W.Initialize()
        local old = W.Game.New(W.Client.Now())
        W.Game.AddHero(old, "WARRIOR")
        W.Game.AddHero(old, "PRIEST")
        old.gold, old.essence, old.legacy = 900, 800, 10
        old.best, old.runBest, old.prestiges, old.prestigeUnlocked = 10, 10, 3, true
        old.adventure = { rank = 2, xp = 0, totalXP = 100, sources = {} }
        old.inventory[1] = W.Game.Item(old, 1, 1, 4, true)
        old.recipes[1], old.discoveries.test, old.guide.dismissed = true, true, true
        old.safe.elwynn = 5
        old.settings.soundEnabled = false
        old.ui.fullscreen, old.ui.compact = false, true
        old.ui.expandedGeometry = { w = 1152, h = 720 }
        W.state = old
        W.catchup = assert(W.Game.BeginCatchup(old, old.lastTime + 60))
        local ui = W.UI
        local frame, preferences = ui.frame, W.preferences
        ui.selected, ui.recruiting = 2, true
        ui.bagPage, ui.bagFilter, ui.confirmPrestige = 7, 6, true
        ui.message = "Old adventure message"
        local action = W.settingsOptions.args.adventure.args.reset
        assertTrue(action.confirm)
        assertTrue(action.confirmText:find("ALL account-wide", 1, true) ~= nil)
        local dialog = LibStub("AceConfigDialog-3.0")
        dialog:Open("AFKraft")
        dialog:SelectGroup("AFKraft", "adventure")
        local function request(widget)
            if widget.type == "Button" and widget.text and widget.text:GetText() == action.name then
                widget:Fire("OnClick")
                return true
            end
            for _, child in ipairs(widget.children or {}) do
                if request(child) then
                    return true
                end
            end
        end
        assertTrue(request(dialog.OpenFrames.AFKraft))
        assertTrue(dialog.popup:IsShown())
        assertTrue(W.state == old and W.catchup ~= nil)
        dialog.popup.cancel:GetScript("OnClick")(dialog.popup.cancel)
        assertTrue(W.state == old and W.catchup ~= nil)
        assertEquals(900, old.gold)
        assertTrue(request(dialog.OpenFrames.AFKraft))
        dialog.popup.accept:GetScript("OnClick")(dialog.popup.accept)
        dialog:Close("AFKraft")
        local state = W.state
        assertTrue(state ~= old)
        assertTrue(AFKraftDB == state)
        assertEquals(0, state.gold)
        assertEquals(0, state.essence)
        assertEquals(0, state.legacy)
        assertEquals(0, state.prestiges)
        assertEquals(0, #state.inventory)
        assertTrue(next(state.recipes) == nil)
        assertTrue(next(state.discoveries) == nil)
        assertEquals(1, state.adventure.rank)
        assertEquals(0, state.adventure.totalXP)
        assertEquals(1, #state.heroes)
        assertEquals(1, W.Game.CompanionSlots(state))
        assertEquals(1, state.heroes[1].level)
        assertEquals("elwynn", state.zone)
        assertEquals(1, state.stage)
        assertFalse(state.guide.dismissed)
        assertTrue(W.catchup == nil)
        assertTrue(ui.frame == frame and W.preferences == preferences)
        assertTrue(state.ui == old.ui and state.settings == old.settings)
        assertFalse(state.settings.soundEnabled)
        assertFalse(state.ui.fullscreen)
        assertFalse(state.ui.compact)
        assertEquals("adventure", state.ui.tab)
        assertEquals(1, ui.selected)
        assertFalse(ui.recruiting)
        assertTrue(ui.bagPage == nil and ui.message == nil)
        assertTrue(ui.frame:IsShown())
        assertEquals(3, W.Panels.GuideStep(state))
        -- Saving and reloading cannot merge the discarded offline snapshot.
        W.Controller:Save()
        assertEquals(0, state.gold)
        assertEquals(0, state.essence)
        local reloaded = assert(W.Game.Load(state, W.Client.Now()))
        assertEquals(1, #reloaded.heroes)
        assertFalse(reloaded.guide.dismissed)
    end
)
