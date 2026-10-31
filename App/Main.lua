local _, W = ...
local G, A = W.Game, W.Client
local root =
    LibStub("AceAddon-3.0"):NewAddon("WoWIdle", "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0")
local update = CreateFrame("Frame")
W.Controller = root
local elapsed = 0

-- Only the live account state announces events; offline snapshots stay silent.
function W.OnLog(state, message)
    if state ~= W.state then
        return
    end
    W.Minimap.Record(message)
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
    local identity = A.Identity()
    state.identities[identity.guid] = identity
    if #state.heroes == 0 then
        if W.Content.classByID[identity.class] then
            G.AddHero(state, identity.class, identity)
        else
            G.AddHero(state, "WARRIOR")
            G.Log(
                state,
                "Your party begins with a warrior companion. Choose the rest of your company in Party."
            )
        end
    end
    W.catchup = G.BeginCatchup(state, A.Now())
    W.CreateUI()
    W.Minimap.Create()
    W.RegisterSettings()
    print("|cffdfbc79WoWIdle|r · /wowidle to enter your adventure.")
end

function root:OnInitialize()
    self:RegisterChatCommand("wowidle", W.Toggle, false)
    self:RegisterChatCommand("wi", W.Toggle, false)
end

function root:OnEnable()
    W.Initialize()
    if W.state then
        A.Register(self)
        self:RegisterEvent("PLAYER_LOGOUT", "Save")
        self:ScheduleRepeatingTimer("RefreshScene", 0.2)
        self:ScheduleRepeatingTimer("RefreshUI", 1)
        update:SetScript("OnUpdate", self.Update)
    end
end

function root:OnDisable()
    update:SetScript("OnUpdate", nil)
    self:Save()
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
            W.UI.scene:Animate()
        else
            W.state.events = nil
        end
    end
    W.Audio.Flush()
end
