local _, W = ...
local G, C = W.Game, W.Content
local Tutorial = {}
W.Tutorial = Tutorial

local function lesson(state, key, tab, message, eligible)
    if eligible and not state.guide[key] then
        return { key = key, tab = tab, message = message }
    end
end

-- Only introduce a layer when it is available; already-used layers need no tour.
function Tutorial.NextLesson(state)
    if #state.heroes == 0 then
        return nil
    end
    local mastery, enchanted, forged, specialized = false, false, false, false
    for _, hero in ipairs(state.heroes) do
        mastery = mastery or (G.MasteryUnlocked(hero) and hero.mastery.rank == 0)
        for _, item in pairs(hero.gear) do
            enchanted = enchanted or item.enchant ~= nil
            forged = forged or (item.forge or 0) > 0
        end
    end
    for _, item in ipairs(state.inventory) do
        enchanted = enchanted or item.enchant ~= nil
        forged = forged or (item.forge or 0) > 0
    end
    local professions = G.ProfessionUnlocks(state)
    for _, allocations in pairs(state.professions.allocations) do
        for _, rank in pairs(allocations) do
            specialized = specialized or rank > 0
        end
    end
    local owned = next(state.boosts.owned) ~= nil
    local affordable = owned
    for _, boost in ipairs(C.boosts) do
        affordable = affordable or state.essence >= boost.cost or state.legacy >= boost.legacyCost
    end
    local automation = state.boosts.automation
    local collection = next(state.dungeonCollections.pieces) ~= nil
        or next(state.outdoorCollections.pieces) ~= nil
        or next(state.collectionBook.pieces) ~= nil
    local huntAvailable = false
    local sources = W.CollectionSources
    local profile = sources and sources.ActiveProfile("outdoor")
    if profile then
        for itemID, source in pairs(profile.sources) do
            huntAvailable = huntAvailable or (source.verified and C.collectionByItem[itemID] ~= nil)
        end
    end
    return lesson(
        state,
        "lessonBoost",
        "boosts",
        "Commander boosts are permanent purchases with temporary effects. Choose an icon, learn and equip it, then activate when the party needs support. Uses are free; cooldowns persist through resets.",
        affordable and (state.stats.boostUses or 0) == 0
    ) or lesson(
        state,
        "lessonDevelopment",
        "development",
        "Essence develops the whole party through Might, Resolve and Provisioning. Compare current and next benefits before buying; rank investment can be redistributed freely without losing learned abilities. Hero levels and equipment do not require Essence.",
        state.development.invested == 0 and state.essence >= G.DevelopmentQuote(state, "might").cost
    ) or lesson(
        state,
        "lessonLegacy",
        "legacy",
        "Heritage is ready. Review the reset preview before beginning a new chapter. Talents, Mastery, owned tools and unspent Essence stay with your company.",
        state.prestigeUnlocked and state.prestiges == 0 and G.PrestigeReward(state) > 0
    ) or lesson(
        state,
        "lessonAutomation",
        "boosts",
        "Spend Heritage in Commander to learn automation once. Enable the global toggle and this boost's Auto-cast, then choose On cooldown or a condition. The waiting reason explains each decision.",
        owned
            and not automation.enabled
            and (automation.owned.onCooldown or state.legacy >= C.boostAutomation.onCooldown.cost)
    ) or lesson(
        state,
        "lessonProfiles",
        "profiles",
        "Profiles save your equipped boost, rules, route preferences and selected collection effect. Save a named setup, then apply it freely. Applying never activates a boost or refreshes its cooldown.",
        next(automation.owned) ~= nil and next(state.boostProfiles.entries) == nil
    ) or lesson(
        state,
        "lessonRoutes",
        "routes",
        "Routes change idle destinations after an encounter. Learn planning, add milestones and save a template; select it and enable Routes. Manual travel pauses it until you resume.",
        (state.routes.owned or (state.prestigeUnlocked and state.legacy >= 1))
            and #state.routes.templates == 0
    ) or lesson(
        state,
        "lessonHunt",
        "collections",
        "Browse outdoor collections and hover over a missing piece to see its creatures and location. Your real WoW character earns discoveries from eligible kills; idle battles and offline routes do not count.",
        huntAvailable and state.adventure.rank >= 2 and next(state.outdoorCollections.pieces) == nil
    ) or lesson(
        state,
        "lessonCollections",
        "collections",
        "Browse outdoor or dungeon sets, hover over pieces for their sources, and select one completed-set effect. Discoveries persist through resets. Earlier collection records remain in legacy history.",
        collection
    ) or lesson(
        state,
        "lessonMastery",
        "talents",
        "Mastery is permanently unlocked at idle level 20. Victories at your encounter frontier earn separate XP and permanent talent points, even at a character level cap. Each difficulty has its own frontier.",
        mastery
    ) or lesson(
        state,
        "lessonEnchanting",
        "workshop",
        "Enchanting is unlocked. In Forge, choose a hero, equipped item and enchantment. Compare the preview and cost before replacing its current enchantment. Heirloom investments survive resets.",
        professions.enchanting and not enchanted
    ) or lesson(
        state,
        "lessonTitanforging",
        "workshop",
        "Titanforging is unlocked. The Forge Titanforge tab raises an equipped item's base potential separately from enhancement and enchantment. Each investment has a guaranteed preview and cost.",
        professions.titanforging and not forged
    ) or lesson(
        state,
        "lessonResearch",
        "workshop",
        "Profession specializations are unlocked. Successful paid work earns separate profession points. Your saved allocation plan survives Transcendence and reactivates as work ranks rebuild.",
        professions.research and not specialized
    ) or lesson(
        state,
        "lessonPrestigePlus",
        "difficulty",
        "Transcendence is ready. Review a deeper reset and an unlocked difficulty. Permanent tools remain; levels, ordinary gear, resources and profession work rebuild. Inheritance rewards each completed tier once.",
        state.difficulty.unlocked and state.difficulty.ascensions == 0
    )
end

function Tutorial.Hide(ui)
    if HelpTip and ui.guideTip then
        HelpTip:Hide(ui.guideOwner, ui.guideTip.text)
    end
    ui.guideTip, ui.guideTarget = nil, nil
end

local function show(ui, target, message, nextStep, side, lessonKey)
    if not HelpTip or not target or not target:IsShown() then
        Tutorial.Hide(ui)
        return
    end
    if ui.guideTarget == target and ui.guideTip and ui.guideTip.text == message then
        if HelpTip:IsShowing(ui.guideOwner, message) then
            return
        end
    end
    Tutorial.Hide(ui)
    if not ui.guideOwner then
        ui.guideOwner = CreateFrame("Frame", nil, ui.expanded)
        ui.guideOwner:SetAllPoints()
        ui.guideOwner:SetFrameStrata("FULLSCREEN_DIALOG")
        ui.guideOwner:EnableMouse(false)
    end
    local state = W.state
    local info = {
        text = message,
        buttonStyle = lessonKey and HelpTip.ButtonStyle.GotIt
            or nextStep and HelpTip.ButtonStyle.Next
            or HelpTip.ButtonStyle.Close,
        targetPoint = side and HelpTip.Point.LeftEdgeCenter or HelpTip.Point.TopEdgeCenter,
        alignment = HelpTip.Alignment.Center,
        autoEdgeFlipping = true,
        autoHorizontalSlide = true,
        autoHideWhenTargetHides = true,
        useParentStrata = true,
        onAcknowledgeCallback = function()
            if W.state ~= state then
                return
            end
            Tutorial.Hide(ui)
            if lessonKey then
                state.guide[lessonKey] = true
            elseif nextStep then
                ui.guideTree = nextStep
            else
                state.guide.dismissed = true
            end
            ui:Refresh()
        end,
    }
    ui.guideTip, ui.guideTarget = info, target
    HelpTip:Show(ui.guideOwner, info, target)
end

function Tutorial.Refresh(ui)
    local s = W.state
    if
        not HelpTip
        or not HelpTip:AreHelpTipsEnabled()
        or W.catchup
        or s.ui.compact
        or s.guide.dismissed
        or not ui.frame:IsShown()
    then
        Tutorial.Hide(ui)
        return
    end
    local step, hero, destination, craft = W.Panels.GuideStep(s, ui.selected)
    if not step then
        local nextLesson = Tutorial.NextLesson(s)
        if nextLesson then
            show(
                ui,
                ui.tabs[nextLesson.tab] or (nextLesson.tab == "workshop" and ui.tabs.crafting),
                nextLesson.message,
                nil,
                true,
                nextLesson.key
            )
        else
            Tutorial.Hide(ui)
        end
        return
    end
    local tab = (step == 2 or step == 6) and "party"
        or step == 3 and "talents"
        or step == 5 and "crafting"
        or "atlas"
    if s.ui.tab ~= tab then
        local messages = {
            [2] = "Your company has equipment it can use. Click Party to equip your first reward.",
            [3] = "You have an unspent talent point. Click Talents to explore your hero’s three talent trees.",
            [4] = "A harder destination is unlocked. Click World map to choose your next frontier.",
            [5] = "You can afford to craft an equipment upgrade for "
                .. s.heroes[hero or ui.selected].name
                .. ". Click Forge to make it.",
            [6] = "Your crafted upgrade is ready. Click Party to equip it from your shared inventory.",
        }
        show(ui, ui.tabs[tab], messages[step], nil, true)
        return
    end
    if hero and (ui.selected ~= hero or ui.recruiting) then
        show(
            ui,
            step == 5 and ui.craftControls and ui.craftControls.hero or ui.cards[hero],
            (step == 5 and "Choose " or "Click ")
                .. s.heroes[hero].name
                .. " to use their available "
                .. (
                    (step == 2 or step == 6) and "equipment."
                    or step == 5 and "crafting upgrade."
                    or "talent point."
                )
        )
        return
    end
    if step == 2 or step == 6 then
        local target = step == 6 and ui.guideCraftEquipTarget or step == 2 and ui.guideEquipTarget
        if target then
            show(
                ui,
                target,
                step == 6
                        and ("Click " .. craft.item.name .. " to equip your crafted upgrade. Its stats take effect immediately.")
                    or "Click this item to equip it. Green power values show improvements; replaced equipment returns to your shared inventory."
            )
        else
            show(
                ui,
                ui.guideInventoryTarget,
                "Click "
                    .. (ui.guideInventoryLabel or "Clear filters")
                    .. " to find equipment this hero can use."
            )
        end
    elseif step == 3 then
        local h = s.heroes[hero]
        if ui.guideTreeHero ~= h then
            ui.guideTreeHero, ui.guideTree = h, 1
        end
        local path = ui.guideTree or 1
        if path <= 3 then
            local names = C.classByID[h.class].paths
            local example = ""
            for _, talent in ipairs(G.TalentList(h)) do
                if talent.path == path and talent.row == 1 then
                    example = "\n\n" .. talent.name .. ": " .. talent.text
                    break
                end
            end
            show(
                ui,
                ui.talentTrees.trees[path],
                names[path]
                    .. " talent tree"
                    .. example
                    .. "\n\nHover icons to compare talents. Green talents can be learned now. Mix trees and respec freely. Talents and earned points survive prestige.",
                path + 1
            )
        else
            for _, talent in ipairs(G.TalentList(h)) do
                if not h.talents[talent.id] and G.CanTalent(h, talent) then
                    local node = ui.talentTrees.trees[talent.path].buttons[talent.id]
                    show(
                        ui,
                        node,
                        "Click "
                            .. talent.name
                            .. " to spend one talent point. You can choose another green talent instead, or click a learned talent later to recover its point."
                    )
                    return
                end
            end
        end
    elseif step == 5 then
        local controls = ui.craftControls
        if (ui.craftHeirloom or false) ~= craft.heirloom then
            show(
                ui,
                craft.heirloom and controls.heirloom or controls.ordinary,
                "Click "
                    .. (craft.heirloom and "Heirloom" or "Ordinary")
                    .. " to use an affordable recipe that improves this hero’s equipment."
            )
        elseif (ui.craftSlot or 1) ~= craft.slot then
            show(
                ui,
                controls.slots[craft.slot],
                "Click " .. C.slots[craft.slot] .. " to craft an upgrade for this equipment slot."
            )
        elseif (ui.craftMaterial or "timber") ~= craft.material then
            show(
                ui,
                controls.materials[craft.material],
                "Click "
                    .. C.materials[craft.material]
                    .. ". You have enough of this material for the recipe; the full cost is shown beside it."
            )
        else
            local h = s.heroes[hero]
            local gain = G.ItemPower(craft.item, h) - G.ItemPower(h.gear[craft.slot], h)
            show(
                ui,
                controls.craft,
                "Click Craft for "
                    .. h.name
                    .. " to make "
                    .. craft.item.name
                    .. " (+"
                    .. gain
                    .. " power). This spends the shown gold and idle materials and puts the item in your shared inventory.",
                nil,
                true
            )
        end
    else
        local focus = ui.atlas.focus
        if not (focus and focus.level > C.zoneByID[s.zone].level and G.IsUnlocked(s, focus)) then
            focus = destination
        end
        for _, map in ipairs(ui.atlas.maps) do
            local x = W.Client.ZonePosition(focus.id, map.id)
            if x then
                show(
                    ui,
                    map,
                    "Hover "
                        .. focus.name
                        .. " on this map, then click its highlighted region to travel to this unlocked, higher frontier."
                )
                return
            end
        end
        Tutorial.Hide(ui)
    end
end
