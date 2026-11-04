local _, W = ...
local L = W.L
local C, G, U, T = W.Content, W.Game, W.Widgets, W.Theme
local P = {}
W.Panels = P

local function text(p, value, x, y, size, color, width)
    return U.Text(p, value, x, y, size or 14, color or T.text, width)
end

local function button(p, label, x, y, w, fn, active, variant)
    return U.Button(p, label, x, y, w, 32, fn, active, variant)
end

local function selected(ui, s)
    return s.heroes[ui.selected or 1], ui.selected or 1
end

-- Opportunities are derived from the current run, never persisted as notifications.
function P.Opportunities(s)
    local points, talentHero, cappedHero, routes = 0, nil, nil, 0
    for i, hero in ipairs(s.heroes) do
        local unspent = G.Points(hero)
        points = points + unspent
        if unspent > 0 and not talentHero then
            talentHero = i
        end
        if
            hero.level >= G.LevelCap(hero)
            and G.LevelCap(hero) < C.heroLevelCap
            and not cappedHero
        then
            cappedHero = i
        end
    end
    for _, zone in ipairs(C.zones) do
        if zone.level > C.zoneByID[s.zone].level and G.IsUnlocked(s, zone) then
            routes = routes + 1
        end
    end
    return points, talentHero, cappedHero, routes
end

-- Return only lessons that can be acted on now; unavailable lessons never block others.
function P.GuideStep(s, selectedHero)
    local craftHero = s.guide.craftHero
    local recipient = craftHero and s.heroes[craftHero]
    if recipient then
        for index, item in ipairs(s.inventory) do
            if
                item.uid == s.guide.craftItem
                and G.CanEquip(recipient, item)
                and G.ItemPower(item, recipient)
                    > G.ItemPower(recipient.gear[item.slot], recipient)
            then
                return 6, craftHero, nil, { item = item, inventoryIndex = index }
            end
        end
    end
    if not s.guide.equipped then
        for index, hero in ipairs(s.heroes) do
            for _, item in ipairs(s.inventory) do
                if G.CanEquip(hero, item) then
                    return 2, index
                end
            end
        end
    end
    if not s.guide.talent then
        for index, hero in ipairs(s.heroes) do
            if G.Points(hero) > 0 then
                for _, talent in ipairs(G.TalentList(hero)) do
                    if not hero.talents[talent.id] and G.CanTalent(hero, talent) then
                        return 3, index
                    end
                end
            end
        end
    end
    if not s.guide.traveled then
        for _, zone in ipairs(C.zones) do
            if zone.level > C.zoneByID[s.zone].level and G.IsUnlocked(s, zone) then
                return 4, nil, zone
            end
        end
    end
    if not s.guide.crafted then
        local index = selectedHero or 1
        local craft = G.CraftingOpportunity(s, index)
        if craft then
            return 5, index, nil, craft
        end
    end
end

local function opportunityCard(parent, y, icon, title, detail, tooltip, action)
    local card = U.SelectButton(parent, "", 710, y, 586, 72, action)
    U.Begin(card)
    U.Icon(card, icon, 12, 18, 36):SetParent(card.content or card)
    card.titleText = U.SingleLine(text(card, title, 62, 10, 16, T.gold, 510), 510, 24)
    card.detailText = U.SingleLine(text(card, detail, 62, 40, 13, T.text, 510), 510, 22)
    U.EndBuild(card)
    U.Tooltip(card, title, tooltip, 380)
    return card
end

function P.DevelopmentOpportunity(state)
    local chosenBranch, selectedQuote
    for _, branch in ipairs(C.development) do
        local quote = G.DevelopmentQuote(state, branch.id)
        if quote and quote.cost and (not selectedQuote or quote.cost < selectedQuote.cost) then
            chosenBranch, selectedQuote = branch, quote
        end
    end
    return chosenBranch, selectedQuote
end

function P.adventure(ui, p, s)
    local title, detail, label, tab
    local step, heroIndex = P.GuideStep(s, ui.selected)
    local points, talentHero, _, destinations = P.Opportunities(s)
    if #s.heroes < G.CompanionSlots(s) then
        title, detail, label, tab =
            L["You found a companion!"],
            L["A new companion is ready to join. Choose their class in Party; they join the next encounter."],
            L["Recruit companions"],
            "party"
    else
        title, detail, label, tab =
            L["Your company is advancing"],
            L["Idle battles earn hero experience, gold, equipment and local materials. WoW activities earn Adventure XP and Essence."],
            L["Manage party"],
            "party"
    end
    if label ~= L["Recruit companions"] then
        if step == 2 or step == 6 then
            title, detail, label =
                L["Equipment ready to use"],
                L["Your shared inventory has equipment for a companion. Compare it with their current gear in Party."],
                L["Review equipment"]
        elseif points > 0 then
            title, detail, label, tab =
                L["Shape your next victory"],
                points
                    .. L[" unspent talent points across your company. Earned points survive chapter resets; changing your build is free."],
                L["Spend talent points"],
                "talents"
            heroIndex = talentHero
        elseif destinations > 0 and not s.farming then
            title, detail, label, tab =
                L["Your next destination awaits"],
                destinations
                    .. L[" higher-level destinations are available. Inspect their rewards and choose where to adventure."],
                L["Explore destinations"],
                "atlas"
        end
    end
    if s.farming and s.lastDefeat and label ~= L["Recruit companions"] then
        title = L["Build strength, then push forward"]
        if s.prestigeUnlocked and G.PrestigeReward(s) > 0 and points == 0 then
            title, label, tab = L["Begin a stronger chapter"], L["Review prestige"], "legacy"
        end
    end
    text(p, L["NEXT STEP"], 0, 0, 12, T.gold)
    text(p, title, 0, 27, 23, T.text, 640)
    if s.farming then
        detail = (s.lastDefeat or L["Your party is farming a safe encounter."])
            .. (
                s.prestigeUnlocked
                    and G.PrestigeReward(s) > 0
                    and L[" Improve your heroes and Retry, or prestige now for permanent party power. Level 60 is not required."]
                or L[" Improve your heroes, then use Retry."]
            )
    end
    U.Help(p, title, 652, 0, detail)
    ui.adventureNext = button(p, label, 0, 128, 240, function()
        ui.recruiting = label == L["Recruit companions"]
        if heroIndex and not ui.recruiting then
            ui.selected = heroIndex
        end
        ui:SetTab(tab)
    end, false, "primary")
    ui.boostQuick = button(p, L["Commander boosts"], 260, 128, 400, function()
        if W.Tutorial.MenuHint(s, "boosts") then
            return
        end
        local id = s.boosts.equipped
        if id then
            W.Action(G.ActivateBoost, id)
        else
            ui:SetTab("boosts")
        end
    end)
    local branch, quote = P.DevelopmentOpportunity(s)
    local upgradeTitle, upgradeDetail =
        L["Growth complete"], L["All three branches are at their rank cap."]
    if branch and quote then
        upgradeTitle = branch.name
            .. L[" rank "]
            .. quote.nextRank
            .. " | "
            .. (
                s.essence >= quote.cost and (quote.cost .. L[" Essence"])
                or (L["Save "] .. (quote.cost - s.essence) .. L[" Essence"])
            )
        local field, caption = "damage", L["Damage"]
        if branch.id == "resolve" then
            field, caption = "health", L["Maximum health"]
        elseif branch.id == "provisioning" then
            field, caption = "materials", L["Zone materials"]
        end
        upgradeDetail = string.format(
            L["%s: %+.1f%% -> %+.1f%% | Review upgrade"],
            caption,
            (quote.current[field] - 1) * 100,
            (quote.next[field] - 1) * 100
        )
    end
    local developmentHint = W.Tutorial.MenuHint(s, "development")
    ui.adventureDevelopment = opportunityCard(
        p,
        0,
        developmentHint and "INV_Misc_QuestionMark"
            or (branch and branch.icon or "Ability_Warrior_BattleShout"),
        developmentHint and "???" or upgradeTitle,
        developmentHint and "" or upgradeDetail,
        developmentHint
            or (branch and branch.description or L["Your permanent development board is complete."])
                .. L["\nOpen Growth to compare every benefit before buying. Rank redistribution is free; learned abilities stay owned."],
        function()
            if not developmentHint then
                ui:SetTab("development")
            end
        end
    )
    local legacyHint = W.Tutorial.MenuHint(s, "legacy")
    local legacyLink = button(
        p,
        legacyHint and "|TInterface\\Icons\\INV_Misc_QuestionMark:18|t ???"
            or (
                s.prestigeUnlocked and L["Heritage +"] .. G.PrestigeReward(s)
                or L["Explore Heritage"]
            ),
        710,
        173,
        160,
        function()
            if not legacyHint then
                ui:SetTab("legacy")
            end
        end
    )
    U.Tooltip(
        legacyLink,
        legacyHint and "???" or L["Heritage"],
        legacyHint or L["Review chapter rewards."]
    )
    if P.GuideStep(s, ui.selected) or (W.Tutorial and W.Tutorial.NextLesson(s)) then
        button(
            p,
            s.guide.dismissed and L["Show guide"] or L["Hide guide"],
            888,
            173,
            154,
            function()
                s.guide.dismissed = not s.guide.dismissed
                ui:Refresh()
            end
        )
    end
    local session = G.HuntSessionSummary(s, W.Client.Now())
    local report = G.HasSessionProgress(session) and session or s.lastHuntSummary
    ui.adventureSession = nil
    if report then
        ui.adventureSession = U.SingleLine(
            text(
                p,
                (report == session and L["Session"] or L["Previous session"])
                    .. " | "
                    .. (report.adventureXP ~= nil and tostring(report.adventureXP) or L["Unrecorded"])
                    .. L[" Adventure XP | "]
                    .. (report.essence ~= nil and tostring(report.essence) or L["Unrecorded"])
                    .. L[" Essence"],
                0,
                169,
                11,
                T.muted,
                660
            ),
            660,
            16
        )
    end
    text(p, L["ADVENTURE JOURNAL"], 0, 187, 11, T.gold)
    ui.offlineReport = nil
    if s.lastOfflineSummary then
        ui.offlineReport = button(p, L["Return report"], 1060, 173, 236, function()
            ui:SetTab("offline")
        end)
    end
    U.SingleLine(text(p, s.log[#s.log] or "", 0, 210, 13, T.muted, 1290), 1290, 24)
end

function P.party(ui, p, s)
    W.PartyPanel.Draw(ui, p, s)
end

function P.offline(ui, p, s)
    W.OfflinePanel.Draw(ui, p, s)
end

function P.development(ui, p, s)
    W.DevelopmentPanel.Draw(ui, p, s)
end

function P.routes(ui, p, s)
    W.RoutePanel.Draw(ui, p, s)
end

function P.profiles(ui, p, s)
    W.ProfilePanel.Draw(ui, p, s)
end

function P.collections(ui, p, s)
    W.CollectionPanel.Draw(ui, p, s)
end

function P.workshop(ui, p, s)
    W.ProfessionPanel.Draw(ui, p, s)
end

function P.difficulty(ui, p, s)
    W.DifficultyPanel.Draw(ui, p, s)
end

function P.boosts(ui, p, s)
    local automation = s.boosts.automation
    local selectedID = C.boostByID[ui.selectedBoost] and ui.selectedBoost
        or s.boosts.equipped
        or C.boosts[1].id
    ui.selectedBoost = selectedID
    ui.boostAutomationPurchases = {}
    for index, capability in ipairs({ "onCooldown", "conditional" }) do
        local spec = C.boostAutomation[capability]
        local control = button(p, "", (index - 1) * 310, 0, 292, function()
            W.Action(G.BuyBoostAutomation, capability)
        end)
        control.text:ClearAllPoints()
        control.text:SetPoint("LEFT", control, "LEFT", 42, 0)
        U.SingleLine(control.text, 240, 24)
        U.Begin(control)
        U.Icon(control, "INV_Misc_Book_09", 7, 5, 22):SetParent(control.content or control)
        U.EndBuild(control)
        U.Tooltip(
            control,
            spec.name .. L[" automation"],
            capability == "onCooldown"
                    and L["Auto-cast the equipped boost when ready in combat. Permanent unlock: 1 Heritage."]
                or L["Unlock boss, ally-health, farming, pushing and ordered rules. Requires On cooldown. Permanent unlock: 2 Heritage."]
        )
        ui.boostAutomationPurchases[capability] = control
    end
    ui.boostAutomationEnabled = U.Checkbox(
        p,
        L["Automation"],
        650,
        0,
        330,
        automation.enabled,
        function(checked)
            W.Action(G.SetBoostAutomationEnabled, checked)
        end
    )
    U.Tooltip(
        ui.boostAutomationEnabled,
        L["Run / pause automation"],
        L["Pause automatic activations without changing saved rules. Manual activation remains available."]
    )
    ui.boostTiles, ui.boostControls = {}, {}
    for index, boost in ipairs(C.boosts) do
        local id = boost.id
        local x, y = ((index - 1) % 5) * 260, 62 + math.floor((index - 1) / 5) * 88
        local tile = U.SelectButton(p, "", x, y, 248, 76, function()
            ui.selectedBoost = id
            ui:Refresh()
        end, selectedID == id)
        U.Begin(tile)
        local icon = U.Icon(tile, boost.icon or "INV_Misc_Book_09", 12, 12, 48)
        icon:SetParent(tile.content or tile)
        U.SingleLine(text(tile, boost.name, 72, 12, 15, T.gold, 164), 164, 24)
        local state = U.SingleLine(text(tile, "", 72, 40, 12, T.muted, 164), 164, 20)
        U.EndBuild(tile)
        U.Tooltip(
            tile,
            boost.name,
            boost.description
                .. L["\n\nLearn once: "]
                .. boost.cost
                .. L[" Essence or "]
                .. boost.legacyCost
                .. L[" Heritage.\n"]
                .. math.floor(boost.duration / 60)
                .. L[" minutes active; "]
                .. math.floor(boost.cooldown / 60)
                .. L[" minutes cooldown from activation. Equip 1 boost; uses are free."],
            320
        )
        ui.boostTiles[id] = { button = tile, state = state, icon = icon }
    end
    local detailY = 62 + math.max(1, math.ceil(#C.boosts / 5)) * 88 + 32
    local boost = C.boostByID[selectedID]
    local id, rule = boost.id, automation.abilities[boost.id]
    U.Icon(p, boost.icon or "INV_Misc_Book_09", 0, detailY, 56)
    text(p, boost.name, 76, detailY, 23, T.gold, 800)
    U.Help(p, boost.name, 1240, detailY, boost.description)
    local purchase = button(p, "", 0, detailY + 84, 180, function()
        W.Action(G.BuyBoost, id)
    end)
    local alternate = button(
        p,
        L["Learn · "] .. boost.legacyCost .. L[" Heritage"],
        190,
        detailY + 84,
        160,
        function()
            W.Action(G.BuyBoost, id, "legacy")
        end
    )
    U.Tooltip(
        purchase,
        L["Permanent boost"],
        L["Learn permanently with Essence or Heritage. Uses are free. Both resets keep ownership and cooldowns, but end active effects."]
    )
    local equip = button(p, L["Equip"], 370, detailY + 84, 170, function()
        W.Action(G.EquipBoost, id)
    end)
    local activate = button(p, L["Activate"], 560, detailY + 84, 260, function()
        W.Action(G.ActivateBoost, id)
    end, false, "primary")
    U.Tooltip(
        activate,
        L["Activate boost"],
        math.floor(boost.duration / 60)
            .. L[" adventure minutes active; "]
            .. math.floor(boost.cooldown / 60)
            .. L[" minutes cooldown from activation. Uses are free. Only 1 boost effect can be active. Timers advance in combat and eligible offline farming."]
    )
    local status = text(p, "", 850, detailY + 92, 14, T.muted, 420)
    local enabled = U.Checkbox(
        p,
        L["Auto-cast"],
        0,
        detailY + 146,
        200,
        rule.enabled,
        function(checked)
            W.Action(G.ConfigureBoostAutomation, id, "enabled", checked)
        end
    )
    local modes, modeName = {}, L["Manual"]
    for _, mode in ipairs(C.boostAutomationModes) do
        if mode.id == rule.mode then
            modeName = mode.name
        end
        if
            mode.id == "manual"
            or (mode.id == "onCooldown" and automation.owned.onCooldown)
            or (mode.id ~= "onCooldown" and automation.owned.conditional)
        then
            modes[#modes + 1] = mode
        end
    end
    local mode = U.Choice(p, modeName, 220, detailY + 146, 500, modes, rule.mode, function(value)
        W.Action(G.ConfigureBoostAutomation, id, "mode", value)
    end)
    mode:SetEnabled(true)
    U.Tooltip(
        mode,
        L["Automatic trigger"],
        L["Auto-casts only the equipped boost during combat. Automation and Auto-cast must both be on."]
    )
    local thresholds = {}
    for _, value in ipairs({ 35, 50, 65, 80 }) do
        thresholds[#thresholds + 1] =
            { id = value, name = L["Ally below "] .. value .. L["% health"] }
    end
    local threshold = U.Choice(
        p,
        L["Ally below "] .. rule.healthBelow .. L["% health"],
        740,
        detailY + 146,
        400,
        thresholds,
        rule.healthBelow,
        function(value)
            W.Action(G.ConfigureBoostAutomation, id, "healthBelow", value)
        end
    )
    threshold:SetEnabled(rule.mode == "lowHealth" and automation.owned.conditional == true)
    threshold:SetShown(rule.mode == "lowHealth")
    U.Tooltip(
        threshold,
        L["Low health trigger"],
        L["Activate when a living ally is below this health percentage."]
    )
    local automaticStatus = text(p, "", 0, detailY + 198, 14, T.muted, 1240)
    ui.boostControls[id] = {
        purchase = purchase,
        alternate = alternate,
        equip = equip,
        activate = activate,
        status = status,
        automationEnabled = enabled,
        mode = mode,
        threshold = threshold,
        automaticStatus = automaticStatus,
    }
    ui.boostRulesToggle = button(
        p,
        (ui.boostRulesExpanded and L["Hide"] or L["Edit"]) .. L[" ordered rules"],
        960,
        detailY + 192,
        284,
        function()
            ui.boostRulesExpanded = not ui.boostRulesExpanded
            ui:Refresh()
        end
    )
    U.Enabled(
        ui.boostRulesToggle,
        automation.owned.conditional == true and s.boosts.owned[id] == true
    )
    if ui.boostRulesExpanded and automation.owned.conditional and s.boosts.owned[id] then
        W.BoostRulePanel.Draw(ui, p, s, id, 0, detailY + 242)
    end
end

local function timer(seconds)
    seconds = math.ceil(seconds)
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

function P.RefreshBoosts(ui, s, message)
    local equipped = s.boosts.equipped
    local function status(id)
        local active, cooldown = G.BoostRemaining(s, id)
        if active > 0 then
            return L["Active "] .. timer(active) .. L[" / Ready "] .. timer(cooldown)
        elseif cooldown > 0 then
            return L["Ready in "] .. timer(cooldown)
        end
        local _, reason = G.CanActivateBoost(s, id)
        return reason
    end
    for _, control in pairs({ ui.boostQuick, ui.compactBoost }) do
        if control then
            local hint = W.Tutorial.MenuHint(s, "boosts")
            local name = hint and "|TInterface\\Icons\\INV_Misc_QuestionMark:18|t ???"
                or (equipped and C.boostByID[equipped].name or L["Commander boosts"])
            if control == ui.boostQuick then
                U.Tooltip(
                    control,
                    hint and "???" or L["Commander boosts"],
                    hint or L["Activate your equipped boost or open Commander."]
                )
            end
            control.text:SetText(name .. (equipped and " · " .. status(equipped) or ""))
            local ready = not equipped or G.CanActivateBoost(s, equipped)
            U.Enabled(control, not W.catchup and ready)
        end
    end
    ui.compactBoost:SetShown(not s.ui.locked and message == nil)
    ui.compactBoost.icon:SetTexture(
        "Interface\\Icons\\" .. (equipped and C.boostByID[equipped].icon or "INV_Misc_Book_09")
    )
    ui.compactHint:SetShown(s.ui.locked or message ~= nil)
    local hint = W.Tutorial.MenuHint(s, "boosts")
    if hint then
        ui.compactBoost.text:SetText("???")
        ui.compactBoost.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    if ui.compactBoost.menuHint ~= hint then
        U.Tooltip(
            ui.compactBoost,
            hint and "???" or L["Commander boosts"],
            hint or L["Activate your equipped boost or open Commander."]
        )
        ui.compactBoost.menuHint = hint
    end
    if s.ui.tab == "boosts" and not W.catchup then
        local automation = s.boosts.automation
        for capability, control in pairs(ui.boostAutomationPurchases or {}) do
            local spec = C.boostAutomation[capability]
            local owned = automation.owned[capability]
            local unlockHint = G.FeatureHint(s, capability)
            U.Tooltip(
                control,
                spec.name .. L[" automation"],
                unlockHint or L["Learn this capability permanently with Heritage."]
            )
            control.text:SetText(
                owned and (spec.name .. L[" · Learned"])
                    or (L["Learn "] .. spec.name .. " · " .. spec.cost .. L[" Heritage"])
            )
            U.Enabled(
                control,
                not owned
                    and not unlockHint
                    and s.legacy >= spec.cost
                    and (capability ~= "conditional" or automation.owned.onCooldown == true)
            )
        end
        if ui.boostAutomationEnabled then
            ui.boostAutomationEnabled:SetChecked(automation.enabled)
        end
        for id, tile in pairs(ui.boostTiles or {}) do
            local active, cooldown = G.BoostRemaining(s, id)
            local owned = s.boosts.owned[id]
            local label = not owned and (C.boostByID[id].cost .. L[" Essence"])
                or active > 0 and (L["Active "] .. timer(active))
                or cooldown > 0 and (L["Cooldown "] .. timer(cooldown))
                or equipped == id and L["Equipped · Ready"]
                or L["Learned"]
            tile.state:SetText(label)
            tile.icon:SetDesaturated(not owned)
            tile.icon:SetAlpha(owned and 1 or 0.45)
        end
        for id, controls in pairs(ui.boostControls or {}) do
            local _, reason = G.BoostAutomationStatus(s, id)
            controls.automaticStatus:SetText(reason)
            controls.automationEnabled:SetChecked(automation.abilities[id].enabled)
            local owned = s.boosts.owned[id]
            controls.purchase.text:SetText(
                owned and L["Learned"] or L["Learn · "] .. C.boostByID[id].cost .. L[" Essence"]
            )
            U.Enabled(
                controls.purchase,
                not owned and not G.FeatureHint(s, "boosts") and s.essence >= C.boostByID[id].cost
            )
            U.Tooltip(
                controls.purchase,
                L["Learn boost"],
                G.FeatureHint(s, "boosts") or L["Spend Essence to learn this boost permanently."]
            )
            controls.alternate:SetShown(not owned)
            U.Enabled(
                controls.alternate,
                not owned
                    and not G.FeatureHint(s, "boosts")
                    and s.legacy >= C.boostByID[id].legacyCost
            )
            U.Tooltip(
                controls.alternate,
                L["Learn boost"],
                G.FeatureHint(s, "boosts") or L["Spend Heritage to learn this boost permanently."]
            )
            controls.equip.text:SetText(equipped == id and L["Equipped"] or L["Equip"])
            U.Enabled(controls.equip, owned and equipped ~= id)
            U.Enabled(controls.activate, G.CanActivateBoost(s, id))
            controls.status:SetText(owned and status(id) or L["Not learned"])
        end
    end
end

function P.talents(ui, p, s)
    local h, index = selected(ui, s)
    U.SingleLine(
        text(p, h.name .. "  /  " .. G.Points(h) .. L[" unspent talent points"], 0, 0, 21, T.gold),
        720,
        28
    )
    local progress = G.TalentProgress(h)
    local nextLevel = G.NextTalentLevel(h)
    local hint = nextLevel and (L["Next level point: "] .. nextLevel .. ". ") or ""
    if progress.earned >= #G.TalentList(h) then
        hint = L["All permanent talent points earned."]
    elseif G.MasteryUnlocked(h) then
        hint = hint
            .. L["Mastery XP: tier "]
            .. s.tier
            .. L[", encounter level "]
            .. math.max(1, G.MasteryFrontier(h, s.tier))
            .. "+."
    else
        hint = hint .. L["Mastery unlocks at hero level "] .. C.mastery.unlockLevel .. "."
    end
    U.Help(
        p,
        L["Talents"],
        688,
        0,
        L["Earn points from new hero level records and Mastery. Click a talent to learn or refund it for free. Points and choices survive both resets.\n\n"]
            .. hint
    )
    W.TalentPanel.Draw(ui, p, h, index)
    text(p, L["COMBAT PRIORITIES"], 0, 490, 12, T.gold)
    U.Choice(p, L["Class presets"], 0, 510, 180, G.PriorityPresets(h), nil, function(id)
        W.Action(G.ConfigurePreset, index, id)
    end)
    local priorities, thresholds = {}, {}
    for _, id in ipairs(C.priorityModes) do
        priorities[#priorities + 1] = { id = id, name = C.priorityNames[id] }
    end
    for n = 35, 85, 10 do
        thresholds[#thresholds + 1] = { id = n, name = L["Recover below "] .. n .. "%" }
    end
    local priority = U.Choice(
        p,
        C.priorityNames[h.priority],
        208,
        510,
        280,
        priorities,
        h.priority,
        function(id)
            W.Action(G.Configure, index, "priority", id)
        end
    )
    local threshold = U.Choice(
        p,
        L["Recover below "] .. h.healBelow .. "%",
        508,
        510,
        300,
        thresholds,
        h.healBelow,
        function(n)
            W.Action(G.Configure, index, "healBelow", n)
        end
    )
    local special = U.Choice(
        p,
        L["Special at "] .. h.specialCount .. L["+ enemies"],
        828,
        510,
        300,
        {
            { id = 1, name = L["Special at 1+ enemies"] },
            { id = 2, name = L["Special at 2+ enemies"] },
            { id = 3, name = L["Special at 3+ enemies"] },
        },
        h.specialCount,
        function(n)
            W.Action(G.Configure, index, "specialCount", n)
        end
    )
    for _, dropdown in ipairs({ priority, threshold, special }) do
        dropdown:SetEnabled(true)
    end
    text(p, L["ENEMY TARGET"], 0, 564, 12, T.gold)
    local targetMode = h.targetMode or "front"
    ui.heroTargetChoice = U.Choice(
        p,
        L["Target: "] .. C.targetModeByID[targetMode].name,
        208,
        556,
        440,
        C.targetModes,
        targetMode,
        function(value)
            W.Action(G.Configure, index, "targetMode", value)
        end
    )
    U.Tooltip(
        ui.heroTargetChoice,
        L["Enemy target priority"],
        L["Choose the primary target for movement, strikes and basic attacks. Health compares percentages; ties use encounter order. Area attacks still hit enemies in range."]
    )
    local profile, value = G.HeroResource(h, s.battle and s.battle.heroes[index])
    if profile then
        local choices = {}
        for _, percent in ipairs({ 0, 25, 50, 75, 100 }) do
            choices[#choices + 1] = {
                id = percent,
                name = profile.name .. L[" abilities >= "] .. percent .. "%",
            }
        end
        local percent = h.resourceThreshold or 0
        ui.heroResourceChoice = U.Choice(
            p,
            profile.name .. L[" abilities >= "] .. percent .. "%",
            668,
            556,
            460,
            choices,
            percent,
            function(n)
                W.Action(G.Configure, index, "resourceThreshold", n)
            end
        )
        U.Tooltip(
            ui.heroResourceChoice,
            profile.name .. ": " .. math.floor(value) .. "/" .. profile.maximum,
            profile.description
                .. L["\n\nAbility costs: strike "]
                .. profile.costs.attack
                .. L["; recovery "]
                .. profile.costs.heal
                .. L["; special "]
                .. profile.costs.special
                .. L[".\nThe threshold is checked before spending. Basic attacks continue while waiting. These resources belong to the minigame."]
        )
    end
end

function P.crafting(ui, p, s)
    local h, index = selected(ui, s)
    local slot = ui.craftSlot or 1
    local material = ui.craftMaterial or "timber"
    local heirloom = ui.craftHeirloom or false
    local cost = G.Cost(s, h, heirloom)
    local preview, unavailable = G.CraftItem(h, slot, heirloom, s)
    ui.craftControls = { slots = {}, materials = {} }
    local heroes = {}
    for heroIndex, hero in ipairs(s.heroes) do
        heroes[#heroes + 1] = { id = heroIndex, name = hero.name }
    end
    ui.craftControls.hero = U.Choice(p, h.name, 0, 0, 425, heroes, index, function(value)
        ui.selected, ui.professionHero = value, value
        ui:Refresh()
    end)
    text(p, L["EQUIPMENT SLOT"], 0, 39, 13, T.gold)
    for position, i in ipairs(C.equipmentSlots) do
        local name, id = C.slots[i], i
        ui.craftControls.slots[i] = U.SelectButton(
            p,
            name,
            (position - 1) % 2 * 220,
            79 + math.floor((position - 1) / 2) * 44,
            205,
            38,
            function()
                ui.craftSlot = id
                ui:Refresh()
            end,
            slot == i
        )
    end
    text(p, L["MATERIAL"], 480, 0, 11, T.gold)
    for i, id in ipairs(C.materialOrder) do
        ui.craftControls.materials[id] = U.SelectButton(
            p,
            C.materials[id] .. " · " .. s.materials[id],
            480,
            48 + (i - 1) * 64,
            310,
            32,
            function()
                ui.craftMaterial = id
                ui:Refresh()
            end,
            material == id
        )
    end
    text(p, preview and L[preview.name] or L["Recipe unavailable"], 850, 0, 23, T.text, 450)
    local description = unavailable
    if preview then
        local quality = heirloom and L["Heirloom"] or C.qualityNames[preview.quality]
        local requirement = heirloom and L["Scales with your hero. Survives chapter resets."]
            or L["Idle level "] .. preview.level
        description = quality .. " · " .. G.ItemPower(preview, h) .. L[" power\n"] .. requirement
    end
    text(p, description, 850, 58, 14, T.muted, 450)
    text(
        p,
        cost.gold .. L[" gold\n"] .. cost.material .. " " .. C.materials[material],
        850,
        141,
        16,
        T.gold,
        450
    )
    local craft = button(p, L["Craft for "] .. h.name, 850, 233, 446, function()
        W.Action(G.Craft, index, slot, material, heirloom)
    end, false, "primary")
    ui.craftControls.craft = craft
    U.Enabled(
        craft,
        preview ~= nil
            and s.gold >= cost.gold
            and s.materials[material] >= cost.material
            and (not heirloom or s.recipes[slot])
    )
    U.Tooltip(
        craft,
        L["Craft targeted equipment"],
        (preview and G.ItemDescription(preview, h) .. "\n\n" or "")
            .. L["Gold and idle materials pay the full cost shown above. Heirloom recipes must first be unlocked in Heritage."]
    )
    if heirloom and not s.recipes[slot] then
        text(p, L["Recipe locked"], 850, 285, 13, T.gold, 446)
    end
    ui.craftControls.ordinary = U.SelectButton(p, L["Ordinary"], 0, 309, 205, 32, function()
        ui.craftHeirloom = false
        ui:Refresh()
    end, not heirloom)
    ui.craftControls.heirloom = U.SelectButton(p, L["Heirloom"], 220, 309, 205, 32, function()
        ui.craftHeirloom = true
        ui:Refresh()
    end, heirloom)
    if heirloom and not s.recipes[slot] then
        button(p, L["View recipe in Heritage"], 850, 325, 446, function()
            ui.legacySlot = slot
            ui:SetTab("legacy")
        end)
    end
end

function P.atlas(ui)
    W.Atlas.Draw(ui)
end

function P.legacy(ui, p, s)
    local reward = G.PrestigeReward(s)
    local currentBonus = (s.prestigeStrength or s.prestiges) * 4
    local nextBonus = currentBonus + reward * 2
    text(
        p,
        ui.confirmPrestige and L["REVIEW YOUR NEW CHAPTER"] or L["CHAPTER REWARDS"],
        0,
        0,
        24,
        T.gold
    )
    text(
        p,
        s.legacy .. L[" Heritage available  ·  "] .. s.prestiges .. L[" rewarded chapters"],
        0,
        44,
        16,
        T.text,
        1296
    )
    text(
        p,
        L["Permanent party bonus: +"] .. currentBonus .. L["% health, damage and healing."],
        0,
        77,
        16,
        T.green,
        1296
    )
    if ui.confirmPrestige then
        text(p, L["GAIN"], 0, 138, 14, T.gold)
        text(
            p,
            "+"
                .. reward
                .. L[" Heritage  ·  Balance after reset: "]
                .. (s.legacy + reward)
                .. L["\nPermanent party bonus: +"]
                .. currentBonus
                .. L["% to +"]
                .. nextBonus
                .. "%",
            0,
            171,
            20,
            T.green,
            1296
        )
        text(p, L["KEEP"], 0, 254, 14, T.gold)
        text(
            p,
            L["Heroes and classes\nTalents, earned points and Mastery\nGrowth, boosts, automation, profiles and routes\nHeirlooms, recipes, collections and Heritage\nAdventure rank, partial XP and unspent Essence\nProfession work and permanent difficulty progress"],
            0,
            287,
            17,
            T.text,
            610
        )
        text(p, L["RESET"], 670, 254, 14, T.gold)
        text(
            p,
            L["Hero levels and XP\nOrdinary equipped and stored gear\nGold, zone materials and Runic fragments\nDestination and encounter progress\nActive boosts end; cooldowns are kept"],
            670,
            287,
            17,
            T.text,
            610
        )
        text(
            p,
            L["Spent Essence is not refunded. This reset cannot be undone."],
            0,
            470,
            16,
            T.gold,
            1220
        )
        button(p, L["Keep adventuring"], 0, 540, 260, function()
            ui.confirmPrestige = false
            ui:Refresh()
        end)
        -- Keep the final action away from the review button's position.
        local confirm = button(p, L["Reset adventure and begin chapter"], 760, 540, 536, function()
            if not ui.confirmPrestige or not s.prestigeUnlocked then
                return
            end
            ui.confirmPrestige = false
            if W.Action(G.Prestige) then
                ui:SetTab("adventure")
            else
                ui:Refresh()
            end
        end, false, "primary")
        U.Enabled(confirm, s.prestigeUnlocked == true)
        return
    end
    text(p, L["NEW CHAPTER"], 0, 142, 14, T.gold)
    U.Help(
        p,
        L["New chapter"],
        624,
        138,
        L["Reset the run to earn Heritage. Each Heritage earned adds 2 percentage points to permanent party health, damage and healing.\n\nReview rewards and losses before confirming. Opening the review does not reset anything."]
    )

    text(
        p,
        s.prestigeUnlocked
                and (L["Available now: +"] .. reward .. L[" Heritage  ·  Party bonus +"] .. currentBonus .. L["% to +"] .. nextBonus .. "%")
            or L["Unlock: defeat a level 8 milestone boss."],
        0,
        190,
        16,
        T.gold,
        620
    )
    if s.prestigeUnlocked and reward == 0 then
        text(
            p,
            L["No Heritage or bonus increase this run. Defeat harder milestone bosses to earn a reward."],
            0,
            235,
            15,
            T.muted,
            620
        )
    end
    local review = button(p, L["Review new chapter…"], 0, 270, 360, function()
        if s.prestigeUnlocked then
            ui.confirmPrestige = true
            ui:Refresh()
        end
    end, false, "primary")
    U.Enabled(review, s.prestigeUnlocked == true)

    text(p, L["HEIRLOOM RECIPES"], 710, 142, 14, T.gold)
    U.Help(
        p,
        L["Heirlooms"],
        1258,
        138,
        L["Heirlooms unlock at difficulty tier 4, scale with hero level and survive both resets.\n\nUnlock a recipe for 1 Heritage, then craft it in Forge with gold and materials. Learning a recipe does not reset your run."]
    )

    for position, i in ipairs(C.equipmentSlots) do
        local name, slot = C.slots[i], i
        local known = s.recipes[i]
        local recipe = button(
            p,
            (known and L["Craft · "] or L["Unlock · "])
                .. name
                .. (known and "" or L[" · 1 Heritage"]),
            710 + (position - 1) % 2 * 302,
            190 + math.floor((position - 1) / 2) * 40,
            285,
            function()
                if s.recipes[slot] or W.Action(G.UnlockRecipe, slot) then
                    ui.craftSlot, ui.craftHeirloom = slot, true
                    ui:SetTab("crafting")
                end
            end,
            known or ui.legacySlot == slot
        )
        U.Tooltip(
            recipe,
            name .. L[" heirloom recipe"],
            known and L["Open Crafting to make this heirloom for the selected hero."]
                or G.FeatureHint(s, "heirlooms")
                or L["Spend 1 Heritage to permanently unlock this recipe, then open Crafting."]
        )
        U.Enabled(recipe, known or (not G.FeatureHint(s, "heirlooms") and s.legacy >= 1))
    end
    text(p, L["COLLECTION TALENTS"], 0, 350, 14, T.gold)
    text(p, L["Permanent ranks · survive both resets"], 0, 378, 13, T.muted, 640)
    ui.collectionTalentButtons = {}
    for index, talent in ipairs(C.collectionTalents) do
        local rank = s.collectionTalents[talent.id] or 0
        local cost = C.collectionTalentCosts[rank + 1]
        local y = 414 + (index - 1) * 76
        text(
            p,
            talent.name .. " · " .. rank .. "/" .. C.collectionTalentRankCap,
            0,
            y,
            16,
            T.gold,
            400
        )
        text(
            p,
            talent.condition
                .. " · +"
                .. math.floor(C.collectionTalentBonus * 100 + 0.5)
                .. L["% of base chance per rank"],
            0,
            y + 26,
            13,
            T.text,
            400
        )
        local learn = button(
            p,
            cost and L["Learn · "] .. cost .. L[" Heritage"] or L["Fully learned"],
            420,
            y,
            220,
            function()
                W.Action(G.BuyCollectionTalent, talent.id)
            end
        )
        ui.collectionTalentButtons[talent.id] = learn
        U.Enabled(learn, cost ~= nil and s.legacy >= (cost or 0))
        U.Tooltip(
            learn,
            talent.name,
            talent.condition
                .. L[" only. Each rank increases collection-piece drop chances by "]
                .. math.floor(C.collectionTalentBonus * 100 + 0.5)
                .. L["% of the base chance, not percentage points. Equipment loot is unchanged.\n\nRanks survive both resets. Each kill rolls independently; no guaranteed discovery."]
        )
    end
end

function P.loot(ui, p, s)
    text(p, L["KEEP RULES"], 0, 0, 19, T.gold)
    U.Help(
        p,
        L["Loot rules"],
        1258,
        0,
        L["Salvage future drops below the selected quality unless a keep rule applies. Heirlooms and protected items are safe.\n\nMatching-loot rules require every selected filter to match. Stored items are unchanged; disenchant them in Party."]
    )
    local qualities = {}
    for quality = 1, 4 do
        qualities[#qualities + 1] =
            { id = quality, name = L["Keep "] .. C.qualityNames[quality] .. "+" }
    end
    U.Choice(
        p,
        L["Keep "] .. C.qualityNames[s.salvage.minQuality] .. "+",
        0,
        79,
        310,
        qualities,
        s.salvage.minQuality,
        function(quality)
            s.salvage.minQuality = quality
            ui:Refresh()
        end
    )
    U.Checkbox(
        p,
        L["Keep potential upgrades"],
        340,
        79,
        310,
        s.salvage.keepUpgrades,
        function(checked)
            s.salvage.keepUpgrades = checked
            ui:Refresh()
        end
    )
    U.Checkbox(
        p,
        L["Keep undiscovered effects"],
        680,
        79,
        350,
        s.salvage.keepEffects,
        function(checked)
            s.salvage.keepEffects = checked
            ui:Refresh()
        end
    )
    text(p, L["Salvaged "] .. s.stats.salvaged .. L[" items"], 0, 132, 14, T.muted)
    text(p, L["ALSO KEEP MATCHING LOOT"], 0, 204, 15, T.gold)
    local classes, slots, stats =
        { { id = "any", name = L["Any class"] } },
        { { id = 0, name = L["Any slot"] } },
        { { id = "any", name = L["Any stat"] } }
    for _, class in ipairs(C.classes) do
        classes[#classes + 1] = { id = class.id, name = class.name }
    end
    for _, slot in ipairs(C.equipmentSlots) do
        slots[#slots + 1] = { id = slot, name = C.slots[slot] }
    end
    for _, stat in ipairs(C.itemStatOrder) do
        stats[#stats + 1] = { id = stat, name = C.itemStatNames[stat] }
    end
    local policy = s.salvage.policy
    local choices = {
        {
            key = "class",
            options = classes,
            label = policy.class == "any" and L["Any class"] or C.classByID[policy.class].name,
        },
        {
            key = "slot",
            options = slots,
            label = policy.slot == 0 and L["Any slot"] or C.slots[policy.slot],
        },
        {
            key = "stat",
            options = stats,
            label = policy.stat == "any" and L["Any stat"] or C.itemStatNames[policy.stat],
        },
    }
    ui.lootPolicyControls = {}
    for index, choice in ipairs(choices) do
        local key = choice.key
        local control = U.Choice(
            p,
            choice.label,
            (index - 1) * 420,
            244,
            400,
            choice.options,
            policy[key],
            function(value)
                W.Action(G.SetLootPolicy, key, value)
            end
        )
        U.Tooltip(
            control,
            L["Keep matching loot"],
            L["Keep future drops matching every selected filter. Class uses maximum armor and weapon proficiency, regardless of current hero level. Other keep rules still apply."],
            380
        )
        ui.lootPolicyControls[key] = control
    end
end

function P.Draw(ui)
    local s = W.state
    local p = ui.panel
    for tab, frame in pairs({
        routes = ui.routeFrame,
        profiles = ui.profileFrame,
        collections = ui.collectionFrame,
        workshop = ui.professionFrame,
    }) do
        if frame then
            frame:SetShown(s.ui.tab == tab and not s.ui.compact and not W.catchup)
        end
    end
    if ui.atlas then
        ui.atlas.frame:SetShown(s.ui.tab == "atlas")
    end
    if ui.talentTrees then
        ui.talentTrees:SetShown(s.ui.tab == "talents" and not W.catchup)
    end
    ui.guideEquipTarget, ui.guideInventoryTarget, ui.guideCraftEquipTarget = nil, nil, nil
    ui.boostQuick, ui.boostControls, ui.boostTiles = nil, nil, nil
    ui.adventureDevelopment, ui.adventureSession = nil, nil
    ui.boostRuleControls, ui.boostRulesToggle = nil, nil
    ui.boostAutomationPurchases, ui.boostAutomationEnabled = nil, nil
    U.Begin(p)
    if W.catchup then
        text(p, L["YOUR PARTY IS RETURNING"], 0, 0, 22, T.gold)
        text(p, L["Resolving your offline adventure…"], 0, 43, 16, T.muted)
    else
        local tab = s.ui.tab or "adventure"
        (P[tab] or P.adventure)(ui, p, s)
    end
    U.EndBuild(p)
end
