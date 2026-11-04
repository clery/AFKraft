local _, W = ...
local L = W.L
local G, C = W.Game, W.Content
local Tutorial = {}
W.Tutorial = Tutorial

-- Menu discoveries persist with the existing guide record across chapters.
function Tutorial.MenuHint(state, id)
    local automation = next(state.boosts.automation.owned) ~= nil
    local professions = G.ProfessionUnlocks(state)
    local best = state.professions.bestLevel
    local conditions = {
        routes = {
            not G.FeatureHint(state, "routes"),
            L["you unlock difficulty tier 3"],
        },
        boosts = {
            not G.FeatureHint(state, "boosts"),
            L["a hero reaches idle level 22"],
        },
        profiles = {
            automation or next(state.boostProfiles.entries) ~= nil,
            L["you learn automation"],
        },
        development = {
            state.essence > 0 or (state.stats.essence or 0) > 0 or state.development.invested > 0,
            L["you earn Essence"],
        },
        collections = {
            state.adventure.rank >= 2 or next(state.outdoorCollections.pieces) ~= nil or next(
                state.dungeonCollections.pieces
            ) ~= nil or next(state.collectionBook.pieces) ~= nil,
            L["you reach Adventure rank 2 or find a collection piece"],
        },
        legacy = {
            state.prestigeUnlocked or state.prestiges > 0 or state.legacy > 0,
            L["you unlock your first chapter reset"],
        },
        difficulty = {
            state.difficulty.unlocked,
            string.format(
                L["a level 60 hero defeats %s in Blackrock Mountain online"],
                C.transcendenceBoss.name
            ),
        },
        enchanting = { professions.enchanting, L["a hero reaches idle level 30"] },
        titanforging = { professions.titanforging, L["a hero reaches idle level 50"] },
        research = { professions.research, L["a hero reaches idle level 60"] },
        crafting = { best >= 1, L["you recruit your first hero"] },
    }
    local condition = conditions[id]
    if not condition then
        return nil
    end
    local key = "menu_" .. id
    if condition[1] then
        state.guide[key] = true
    end
    if state.guide[key] ~= true then
        return L["Discover this when "] .. condition[2] .. "."
    end
end

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
        L["Choose a Commander boost, learn it and equip it. Activate for temporary party support. Uses are free; cooldowns survive both resets."],
        not G.FeatureHint(state, "boosts") and affordable and (state.stats.boostUses or 0) == 0
    ) or lesson(
        state,
        "lessonDevelopment",
        "development",
        L["Spend Essence in Growth for permanent party bonuses. Compare Current and Next rank before buying. Refund ranks for free; hero levels and equipment need no Essence."],
        state.development.invested == 0 and state.essence >= G.DevelopmentQuote(state, "might").cost
    ) or lesson(
        state,
        "lessonLegacy",
        "legacy",
        L["Review your first chapter reset in Heritage. Check the rewards and losses before confirming. Permanent progress stays with your company."],
        state.prestigeUnlocked and state.prestiges == 0 and G.PrestigeReward(state) > 0
    ) or lesson(
        state,
        "lessonAutomation",
        "boosts",
        L["Learn automation in Commander with Heritage. Turn on Automation and Auto-cast, then choose a trigger. The status explains why it is waiting."],
        owned
            and not automation.enabled
            and not G.FeatureHint(state, "onCooldown")
            and (automation.owned.onCooldown or state.legacy >= C.boostAutomation.onCooldown.cost)
    ) or lesson(
        state,
        "lessonProfiles",
        "profiles",
        L["Save your boost, automation, route preferences and set effect in a profile. Apply it for free; cooldowns and active effects stay unchanged."],
        next(automation.owned) ~= nil and next(state.boostProfiles.entries) == nil
    ) or lesson(
        state,
        "lessonRoutes",
        "routes",
        L["Learn route planning, add destinations and milestones, then save and enable the route. Travel happens between encounters. Manual travel pauses it until Resume."],
        not G.FeatureHint(state, "routes")
            and (state.routes.owned or state.legacy >= 1)
            and #state.routes.templates == 0
    ) or lesson(
        state,
        "lessonHunt",
        "collections",
        L["Hover a missing collection piece for its creatures, location and chance. Hunt with your real WoW character; idle battles and offline routes do not count."],
        huntAvailable and state.adventure.rank >= 2 and next(state.outdoorCollections.pieces) == nil
    ) or lesson(
        state,
        "lessonCollections",
        "collections",
        L["Browse sets and hover pieces for their sources. Complete a set to select its effect. Only 1 set effect can be active; discoveries survive both resets."],
        collection
    ) or lesson(
        state,
        "lessonMastery",
        "talents",
        L["Mastery unlocks permanently at hero level 20. Win at your current-tier encounter frontier or higher to earn XP. Each Mastery rank adds 1 permanent talent point."],
        mastery
    ) or lesson(
        state,
        "lessonEnchanting",
        "workshop",
        L["Enchanting is unlocked in Forge. Choose a hero, equipped item and enchantment. Applying replaces the old enchantment; heirloom upgrades survive both resets."],
        professions.enchanting and not enchanted
    ) or lesson(
        state,
        "lessonTitanforging",
        "workshop",
        L["Titanforging is unlocked in Forge. Raise equipped item potential through 5 tiers, separately from enhancement and enchanting. Check the preview and cost before applying."],
        professions.titanforging and not forged
    ) or lesson(
        state,
        "lessonResearch",
        "workshop",
        L["Specializations are unlocked in Forge. Paid work earns profession points. Your plan survives Transcendence and reactivates as work ranks rebuild."],
        professions.research and not specialized
    ) or lesson(
        state,
        "lessonPrestigePlus",
        "difficulty",
        L["Transcendence is unlocked. Review a tier and its reset losses before confirming. Permanent tools remain; profession work resets. Each completed tier pays Inheritance once."],
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
            [2] = L["Your company has equipment it can use. Click Party to equip your first reward."],
            [3] = L["You have an unspent talent point. Click Talents to explore your hero’s three talent trees."],
            [4] = L["A harder destination is unlocked. Click World map to choose your next frontier."],
            [5] = L["You can afford to craft an equipment upgrade for "]
                .. s.heroes[hero or ui.selected].name
                .. L[". Click Forge to make it."],
            [6] = L["Your crafted upgrade is ready. Click Party to equip it from your shared inventory."],
        }
        show(ui, ui.tabs[tab], messages[step], nil, true)
        return
    end
    if hero and (ui.selected ~= hero or ui.recruiting) then
        show(
            ui,
            step == 5 and ui.craftControls and ui.craftControls.hero or ui.cards[hero],
            (step == 5 and L["Choose "] or L["Click "])
                .. s.heroes[hero].name
                .. L[" to use their available "]
                .. (
                    (step == 2 or step == 6) and L["equipment."]
                    or step == 5 and L["crafting upgrade."]
                    or L["talent point."]
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
                        and (L["Click "] .. L[craft.item.name] .. L[" to equip your crafted upgrade. Its stats take effect immediately."])
                    or L["Click this item to equip it. Green power values show improvements; replaced equipment returns to your shared inventory."]
            )
        else
            show(
                ui,
                ui.guideInventoryTarget,
                L["Click "]
                    .. (ui.guideInventoryLabel or L["Clear filters"])
                    .. L[" to find equipment this hero can use."]
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
                    .. L[" talent tree"]
                    .. example
                    .. L["\n\nHover icons to compare talents. Green talents can be learned now. Mix trees and respec freely. Talents and earned points survive prestige."],
                path + 1
            )
        else
            for _, talent in ipairs(G.TalentList(h)) do
                if not h.talents[talent.id] and G.CanTalent(h, talent) then
                    local node = ui.talentTrees.trees[talent.path].buttons[talent.id]
                    show(
                        ui,
                        node,
                        L["Click "]
                            .. talent.name
                            .. L[" to spend 1 talent point, or choose another green talent. Click a learned talent to refund it for free."]
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
                L["Click "]
                    .. (craft.heirloom and L["Heirloom"] or L["Ordinary"])
                    .. L[" to use an affordable recipe that improves this hero’s equipment."]
            )
        elseif (ui.craftSlot or 1) ~= craft.slot then
            show(
                ui,
                controls.slots[craft.slot],
                L["Click "]
                    .. C.slots[craft.slot]
                    .. L[" to craft an upgrade for this equipment slot."]
            )
        elseif (ui.craftMaterial or "timber") ~= craft.material then
            show(
                ui,
                controls.materials[craft.material],
                L["Click "]
                    .. C.materials[craft.material]
                    .. L[". You have enough of this material for the recipe; the full cost is shown beside it."]
            )
        else
            local h = s.heroes[hero]
            local gain = G.ItemPower(craft.item, h) - G.ItemPower(h.gear[craft.slot], h)
            show(
                ui,
                controls.craft,
                L["Click Craft for "]
                    .. h.name
                    .. L[" to make "]
                    .. L[craft.item.name]
                    .. " (+"
                    .. gain
                    .. L[" power). This spends the shown gold and idle materials and puts the item in your shared inventory."],
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
                    L["Hover "]
                        .. focus.name
                        .. L[" for its rewards, then click to travel. Travel abandons the current encounter without rewards."]
                )
                return
            end
        end
        Tutorial.Hide(ui)
    end
end
