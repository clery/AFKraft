local _, W = ...
local G, A = W.Game, W.Client
local root =
    LibStub("AceAddon-3.0"):NewAddon("WoWIdle", "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0")
local update = CreateFrame("Frame")
W.Controller = root
local elapsed = 0

-- Only the live account state announces events; offline snapshots stay silent.
function W.OnLog(state, message, noticeType)
    if state ~= W.state then
        return
    end
    W.Minimap.Record(message, noticeType)
    if state.settings.chatAnnouncements then
        print("|cffdfbc79WoWIdle:|r " .. message)
    end
end

function W.Notify(message)
    if W.UI then
        W.UI.message = message
        W.UI.messageUntil = GetTime() + 6
        W.UI:Refresh()
    end
end

function W.Action(fn, ...)
    if W.catchup then
        W.Notify("Your party is returning from its adventure.")
        return
    end
    local ok, message = fn(W.state, ...)
    if message then
        W.Notify(message)
    end
    if W.UI then
        W.UI:Refresh()
    end
    return ok
end

function W.Toggle()
    if not W.state then
        return
    end
    if not W.UI then
        W.CreateUI()
    end
    W.UI.frame:SetShown(not W.UI.frame:IsShown())
end

local function startingHero(state)
    local identity = A.Identity()
    state.identities[identity.guid] = identity
    if #state.heroes == 0 then
        if W.Content.classByID[identity.class] then
            G.AddHero(state, identity.class, identity)
        else
            G.AddHero(state, "WARRIOR")
            G.Log(
                state,
                "Your adventure begins with one warrior. Defeat milestone bosses to find companions."
            )
        end
    end
end

function W.Initialize()
    if W.state then
        return
    end
    local state, errorMessage = G.Load(WoWIdleDB, A.Now())
    if not state then
        print("|cffffcc66WoWIdle:|r " .. errorMessage)
        return
    end
    local bound
    bound, errorMessage = W.BindPreferences(state)
    if not bound then
        print("|cffffcc66WoWIdle:|r " .. errorMessage)
        return
    end
    W.state = state
    WoWIdleDB = state
    startingHero(state)
    G.BeginHuntSession(state, A.Now())
    W.catchup = G.BeginCatchup(state, A.Now())
    W.CreateUI()
    W.Minimap.Create()
    W.RegisterSettings()
    print("|cffdfbc79WoWIdle|r · /wowidle to enter your adventure.")
end

-- Called by the confirmed Settings action. Replace the saved gameplay state
-- without rebuilding frames, rebinding preferences, or re-registering events.
function W.ResetAdventure()
    if not W.state then
        return
    end
    local previous = W.state
    local state = G.New(A.Now())
    state.ui, state.settings = previous.ui, previous.settings
    state.ui.tab, state.ui.compact, state.ui.minimapNotice = "adventure", false, nil
    W.catchup = nil
    elapsed = 0
    W.Audio.Stop()
    W.state, WoWIdleDB = state, state
    G.BeginHuntSession(state, A.Now())
    startingHero(state)
    local ui = W.UI
    for _, key in ipairs({
        "craftSlot",
        "craftHeirloom",
        "craftMaterial",
        "legacySlot",
        "lootPage",
        "gearSlot",
        "bagFilter",
        "bagFiltersOpen",
        "bagPage",
        "bagView",
        "confirmPrestige",
        "message",
        "messageUntil",
    }) do
        ui[key] = nil
    end
    ui.selected, ui.recruiting = 1, false
    if ui.atlas then
        ui.atlas.focus = nil
    end
    if ui.map then
        ui.map:Hide()
    end
    for _, unit in ipairs(ui.scene.units) do
        unit.floatAnimation:Stop()
        unit.floating:SetAlpha(0)
    end
    state.ui.minimapNotice = nil
    state.ui.minimapNotices = nil
    W.Minimap.Refresh()
    ui:ApplyMode()
    ui.frame:Show()
end

function root:OnInitialize()
    self:RegisterChatCommand("wowidle", W.Toggle, false)
    self:RegisterChatCommand("wi", W.Toggle, false)
end

function root:OnEnable()
    W.Initialize()
    if W.state then
        A.Register(self)
        W.preferences.RegisterCallback(self, "OnDatabaseShutdown", "Save")
        self:ScheduleRepeatingTimer("RefreshScene", 0.2)
        self:ScheduleRepeatingTimer("RefreshUI", 1)
        update:SetScript("OnUpdate", self.Update)
    end
end

function root:OnDisable()
    update:SetScript("OnUpdate", nil)
    self:Save()
    if W.preferences then
        W.preferences.UnregisterCallback(self, "OnDatabaseShutdown")
    end
    if W.UI then
        W.UI.frame:Hide()
    end
    W.Audio.Stop()
end

function root:Save()
    if not W.state then
        return
    end
    if W.catchup then
        G.FinishCatchup(W.state, W.catchup)
        W.catchup = nil
    else
        W.state.lastTime = math.max(W.state.lastTime or 0, A.Now())
    end
    G.SaveHuntSession(W.state, A.Now())
    W.state.events = nil
end

function root:OnGameEvent(event, ...)
    if W.state then
        A.Event(W.state, event, ...)
    end
end

function root:RefreshScene()
    if not W.state then
        return
    end
    A.Sample(W.state)
    if not W.catchup and W.UI.frame:IsShown() then
        W.UI.scene:Refresh(W.state)
    end
end

function root:RefreshUI()
    if W.state and not W.catchup and W.UI.frame:IsShown() then
        W.UI:Refresh(false)
    end
end

function root.Update(_, dt)
    if not W.state then
        return
    end
    if W.catchup then
        if G.CatchupBatch(W.catchup, 1200) then
            G.FinishCatchup(W.state, W.catchup)
            W.catchup = nil
            W.UI:Refresh()
        end
        return
    end
    elapsed = elapsed + dt
    -- Bound per-frame work; preserve the backlog instead of dropping elapsed time.
    local steps = 0
    while elapsed >= 0.25 and steps < 16 do
        G.Step(W.state, 0.25)
        elapsed = elapsed - 0.25
        steps = steps + 1
    end
    W.state.lastTime = math.max(W.state.lastTime or 0, A.Now())
    if W.UI then
        if W.UI.frame:IsShown() then
            W.UI.scene:Animate(dt, elapsed / 0.25)
        else
            W.state.events = nil
        end
    end
    W.Audio.Flush()
end
