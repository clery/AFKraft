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
            L.YOU_UNLOCK_DIFFICULTY_TIER_3,
        },
        boosts = {
            not G.FeatureHint(state, "boosts"),
            L.A_HERO_REACHES_IDLE_LEVEL_22,
        },
        profiles = {
            automation or next(state.boostProfiles.entries) ~= nil,
            L.YOU_LEARN_AUTOMATION,
        },
        development = {
            state.essence > 0 or (state.stats.essence or 0) > 0 or state.development.invested > 0,
            L.YOU_EARN_ESSENCE,
        },
        collections = {
            state.adventure.rank >= 2 or next(state.outdoorCollections.pieces) ~= nil or next(
                state.dungeonCollections.pieces
            ) ~= nil or next(state.collectionBook.pieces) ~= nil,
            L.YOU_REACH_ADVENTURE_RANK_2_OR_FIND_A_COLLECTION,
        },
        legacy = {
            state.prestigeUnlocked or state.prestiges > 0 or state.legacy > 0,
            L.YOU_UNLOCK_YOUR_FIRST_CHAPTER_RESET,
        },
        difficulty = {
            state.difficulty.unlocked,
            string.format(
                L.A_LEVEL_60_HERO_DEFEATS_IN_BLACKROCK_MOUNTAIN_ONLINE,
                C.transcendenceBoss.name
            ),
        },
        enchanting = { professions.enchanting, L.A_HERO_REACHES_IDLE_LEVEL_30 },
        titanforging = { professions.titanforging, L.A_HERO_REACHES_IDLE_LEVEL_50 },
        research = { professions.research, L.A_HERO_REACHES_IDLE_LEVEL_60 },
        crafting = { best >= 1, L.YOU_RECRUIT_YOUR_FIRST_HERO },
        onCooldown = { not G.FeatureHint(state, "onCooldown"), C.featureMilestones.onCooldown.hint },
        conditional = {
            not G.FeatureHint(state, "conditional"),
            C.featureMilestones.conditional.hint,
        },
        heirlooms = { not G.FeatureHint(state, "heirlooms"), C.featureMilestones.heirlooms.hint },
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
        return L.DISCOVER_THIS_WHEN_PREFIX .. condition[2] .. "."
    end
end

-- Introduce unlocked layers even before the player can afford their first purchase.
function Tutorial.NextLesson(state)
    if #state.heroes == 0 then
        return nil
    end
    local mastery = false
    for _, hero in ipairs(state.heroes) do
        mastery = mastery or G.MasteryUnlocked(hero)
    end
    local professions = G.ProfessionUnlocks(state)
    local huntAvailable = false
    local sources = W.CollectionSources
    local profile = sources and sources.ActiveProfile("outdoor")
    if profile then
        for itemID, source in pairs(profile.sources) do
            huntAvailable = huntAvailable or (source.verified and C.collectionByItem[itemID] ~= nil)
        end
    end
    local lessons = {
        {
            "lessonBoost",
            "boosts",
            L.CHOOSE_A_COMMANDER_BOOST_LEARN_IT_AND_EQUIP_IT,
            not Tutorial.MenuHint(state, "boosts"),
        },
        {
            "lessonDevelopment",
            "development",
            L.SPEND_ESSENCE_IN_GROWTH_FOR_PERMANENT_PARTY_BONUSES_COMPARE,
            not Tutorial.MenuHint(state, "development"),
        },
        {
            "lessonLegacy",
            "legacy",
            L.REVIEW_YOUR_FIRST_CHAPTER_RESET_IN_HERITAGE_CHECK_THE,
            not Tutorial.MenuHint(state, "legacy"),
        },
        {
            "lessonAutomation",
            "boosts",
            L.LEARN_AUTOMATION_IN_COMMANDER_WITH_HERITAGE_TURN_ON_AUTOMATION,
            not Tutorial.MenuHint(state, "onCooldown"),
        },
        {
            "lessonProfiles",
            "profiles",
            L.SAVE_YOUR_BOOST_AUTOMATION_ROUTE_PREFERENCES_AND_SET_EFFECT,
            not Tutorial.MenuHint(state, "profiles"),
        },
        {
            "lessonRoutes",
            "routes",
            L.LEARN_ROUTE_PLANNING_ADD_DESTINATIONS_AND_MILESTONES_THEN_SAVE,
            not Tutorial.MenuHint(state, "routes"),
        },
        {
            "lessonHunt",
            "collections",
            L.HOVER_A_MISSING_COLLECTION_PIECE_FOR_ITS_CREATURES_LOCATION,
            huntAvailable
                and state.adventure.rank >= 2
                and next(state.outdoorCollections.pieces) == nil,
        },
        {
            "lessonCollections",
            "collections",
            L.BROWSE_SETS_AND_HOVER_PIECES_FOR_THEIR_SOURCES_COMPLETE,
            not Tutorial.MenuHint(state, "collections"),
        },
        {
            "lessonMastery",
            "talents",
            L.MASTERY_UNLOCKS_PERMANENTLY_AT_HERO_LEVEL_20_WIN_AT,
            mastery,
        },
        {
            "lessonEnchanting",
            "workshop",
            L.ENCHANTING_IS_UNLOCKED_IN_FORGE_CHOOSE_A_HERO_EQUIPPED,
            professions.enchanting,
        },
        {
            "lessonTitanforging",
            "workshop",
            L.TITANFORGING_IS_UNLOCKED_IN_FORGE_RAISE_EQUIPPED_ITEM_POTENTIAL,
            professions.titanforging,
        },
        {
            "lessonResearch",
            "workshop",
            L.SPECIALIZATIONS_ARE_UNLOCKED_IN_FORGE_PAID_WORK_EARNS_PROFESSION,
            professions.research,
        },
        {
            "lessonPrestigePlus",
            "difficulty",
            L.TRANSCENDENCE_IS_UNLOCKED_REVIEW_A_TIER_AND_ITS_RESET,
            not Tutorial.MenuHint(state, "difficulty"),
        },
        {
            "lessonConditional",
            "boosts",
            L.UNLOCK_BOSS_ALLY_HEALTH_FARMING_PUSHING_AND_ORDERED_RULES,
            not Tutorial.MenuHint(state, "conditional"),
        },
        {
            "lessonHeirlooms",
            "legacy",
            L.HEIRLOOM_RECIPES_DESCRIPTION,
            not Tutorial.MenuHint(state, "heirlooms"),
        },
    }
    local nextLesson
    for _, entry in ipairs(lessons) do
        local key, tab, message, eligible = unpack(entry)
        if eligible then
            local availableKey = key .. "Available"
            if not state.guide[availableKey] then
                state.guide[availableKey] = true
                if not state.guide[key] then
                    state.guide.dismissed = false
                end
            end
            if not nextLesson and not state.guide[key] then
                nextLesson = { key = key, tab = tab, message = message }
            end
        end
    end
    return nextLesson
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
            [2] = L.YOUR_COMPANY_HAS_EQUIPMENT_IT_CAN_USE_CLICK_PARTY,
            [3] = L.YOU_HAVE_AN_UNSPENT_TALENT_POINT_CLICK_TALENTS_TO,
            [4] = L.A_HARDER_DESTINATION_IS_UNLOCKED_CLICK_WORLD_MAP_TO,
            [5] = L.YOU_CAN_AFFORD_TO_CRAFT_AN_EQUIPMENT_UPGRADE_FOR_PREFIX
                .. s.heroes[hero or ui.selected].name
                .. L.CLICK_FORGE_TO_MAKE_IT,
            [6] = L.YOUR_CRAFTED_UPGRADE_IS_READY_CLICK_PARTY_TO_EQUIP,
        }
        show(ui, ui.tabs[tab], messages[step], nil, true)
        return
    end
    if hero and (ui.selected ~= hero or ui.recruiting) then
        show(
            ui,
            step == 5 and ui.craftControls and ui.craftControls.hero or ui.cards[hero],
            (step == 5 and L.CHOOSE_PREFIX or L.CLICK_PREFIX)
                .. s.heroes[hero].name
                .. L.FRAGMENT_TO_USE_THEIR_AVAILABLE
                .. (
                    (step == 2 or step == 6) and L.EQUIPMENT_2
                    or step == 5 and L.CRAFTING_UPGRADE
                    or L.TALENT_POINT
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
                        and (L.CLICK_PREFIX .. G.ItemName(craft.item) .. L.TO_EQUIP_YOUR_CRAFTED_UPGRADE_ITS_STATS_TAKE_EFFECT_SUFFIX)
                    or L.CLICK_THIS_ITEM_TO_EQUIP_IT_GREEN_POWER_VALUES
            )
        else
            show(
                ui,
                ui.guideInventoryTarget,
                ui.guideInventoryLabel == L.SCROLL_HORIZONTAL_HINT and L.SCROLL_HORIZONTAL_HINT
                    or L.CLICK_PREFIX
                        .. (ui.guideInventoryLabel or L.CLEAR_FILTERS)
                        .. L.TO_FIND_EQUIPMENT_THIS_HERO_CAN_USE_SUFFIX
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
                    .. L.TALENT_TREE_SUFFIX
                    .. example
                    .. L.HOVER_ICONS_TO_COMPARE_TALENTS_GREEN_TALENTS_CAN_BE_SUFFIX,
                path + 1
            )
        else
            for _, talent in ipairs(G.TalentList(h)) do
                if G.CanTalent(h, talent) then
                    local node = ui.talentTrees.trees[talent.path].buttons[talent.id]
                    show(
                        ui,
                        node,
                        L.CLICK_PREFIX
                            .. talent.name
                            .. L.TO_SPEND_1_TALENT_POINT_OR_CHOOSE_ANOTHER_GREEN_SUFFIX
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
                L.CLICK_PREFIX
                    .. (craft.heirloom and L.HEIRLOOM or L.ORDINARY)
                    .. L.TO_USE_AN_AFFORDABLE_RECIPE_THAT_IMPROVES_THIS_HERO_SUFFIX
            )
        elseif (ui.craftSlot or 1) ~= craft.slot then
            show(
                ui,
                controls.slots[craft.slot],
                L.CLICK_PREFIX
                    .. C.slots[craft.slot]
                    .. L.TO_CRAFT_AN_UPGRADE_FOR_THIS_EQUIPMENT_SLOT_SUFFIX
            )
        elseif (ui.craftMaterial or "timber") ~= craft.material then
            show(
                ui,
                controls.materials[craft.material],
                L.CLICK_PREFIX
                    .. C.materials[craft.material]
                    .. L.YOU_HAVE_ENOUGH_OF_THIS_MATERIAL_FOR_THE_RECIPE
            )
        else
            local h = s.heroes[hero]
            local gain = G.ItemPower(craft.item, h) - G.ItemPower(h.gear[craft.slot], h)
            show(
                ui,
                controls.craft,
                L.CLICK_CRAFT_FOR_PREFIX
                    .. h.name
                    .. L.FRAGMENT_TO_MAKE
                    .. G.ItemName(craft.item)
                    .. " (+"
                    .. gain
                    .. L.POWER_THIS_SPENDS_THE_SHOWN_GOLD_AND_IDLE_MATERIALS_SUFFIX,
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
                    L.HOVER_PREFIX
                        .. focus.name
                        .. L.FOR_ITS_REWARDS_THEN_CLICK_TO_TRAVEL_TRAVEL_ABANDONS_SUFFIX
                )
                return
            end
        end
        Tutorial.Hide(ui)
    end
end
