local _, W = ...
local G, C = W.Game, W.Content
local Tutorial = {}
W.Tutorial = Tutorial

function Tutorial.Hide(ui)
    if HelpTip and ui.guideTip then
        HelpTip:Hide(ui.guideOwner, ui.guideTip.text)
    end
    ui.guideTip, ui.guideTarget = nil, nil
end

local function show(ui, target, message, nextStep, side)
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
        buttonStyle = nextStep and HelpTip.ButtonStyle.Next or HelpTip.ButtonStyle.Close,
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
            if nextStep then
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
    local step, hero, destination = W.Panels.GuideStep(s)
    if not step then
        Tutorial.Hide(ui)
        return
    end
    local tab = step == 2 and "party" or step == 3 and "talents" or "atlas"
    if s.ui.tab ~= tab then
        local messages = {
            [2] = "Your company has equipment it can use. Click Party to equip your first reward.",
            [3] = "You have an unspent talent point. Click Talents to explore your hero’s three talent trees.",
            [4] = "A harder destination is unlocked. Click World map to choose your next frontier.",
        }
        show(ui, ui.tabs[tab], messages[step], nil, true)
        return
    end
    if hero and (ui.selected ~= hero or ui.recruiting) then
        show(
            ui,
            ui.cards[hero],
            "Click "
                .. s.heroes[hero].name
                .. " to use their available "
                .. (step == 2 and "equipment." or "talent point.")
        )
        return
    end
    if step == 2 then
        if ui.guideEquipTarget then
            show(
                ui,
                ui.guideEquipTarget,
                "Click this item to equip it. Green power values show improvements; replaced equipment returns to your shared inventory."
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
                    .. "\n\nHover icons to compare talents. Green talents can be learned now. Mix trees and change talents freely.",
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
