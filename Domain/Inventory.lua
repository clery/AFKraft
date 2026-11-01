local _, W = ...
local C, G = W.Content, W.Game
local copy = G.Copy

-- Crafting and migrated saves choose the closest catalog entry for their slot.
function G.Item(state, slot, level, quality, heirloom, template)
    if not C.slots[slot] then
        return nil
    end
    if not template then
        local distance
        for _, candidate in ipairs(C.items) do
            if candidate.slot == slot then
                local score = math.abs(candidate.level - level) * 10
                    + math.abs(candidate.quality - quality)
                    + (not heirloom and candidate.level > level and 100000 or 0)
                if not distance or score < distance then
                    template, distance = candidate, score
                end
            end
        end
    end
    if not template then
        return nil
    end
    local item = copy(template)
    item.uid, item.slot, item.upgrade, item.heirloom = state.nextItem, slot, 0, heirloom
    -- These are idle requirements; the original WoW requirement remains available.
    item.level = level
    state.nextItem = state.nextItem + 1
    return item
end

function G.ZoneLoot(state, level)
    local pool = C.zoneItems[state.zone]
    local candidates = {}
    for _, id in ipairs(pool) do
        local template = C.itemByID[id]
        if template.level <= level then
            -- Uncommon finds are more frequent than rare finds.
            local weight = template.quality == 3 and 1 or 4
            for _ = 1, weight do
                candidates[#candidates + 1] = template
            end
        end
    end
    if #candidates == 0 then
        return nil
    end
    local template = candidates[G.Random(state, #candidates)]
    return G.Item(state, template.slot, template.level, template.quality, false, template)
end

function G.SameItem(a, b)
    if a.itemID ~= b.itemID or a.name ~= b.name then
        return false
    end
    for _, key in ipairs(C.itemStatOrder) do
        if (a.stats or {})[key] ~= (b.stats or {})[key] then
            return false
        end
    end
    return true
end

function G.IsUpgrade(state, item)
    for _, hero in ipairs(state.heroes) do
        if
            (item.heirloom or item.level <= hero.level)
            and G.ItemPower(item, hero) > G.ItemPower(hero.gear[item.slot], hero)
        then
            return true
        end
    end
    return false
end

function G.Salvage(state, item)
    if item.heirloom or item.protected then
        return false
    end
    local count = item.count or 1
    state.gold = state.gold + item.level * item.quality * 2 * count
    state.materials.ore = state.materials.ore + item.quality * count
    state.stats.salvaged = state.stats.salvaged + count
    return true
end

function G.Loot(state, item)
    if item.quality >= 3 then
        G.Emit(state, "loot")
    end
    local newEffect = item.effect and not state.discoveries["effect:" .. item.effect]
    local keep = item.heirloom
        or item.protected
        or item.quality >= state.salvage.minQuality
        or (state.salvage.keepUpgrades and G.IsUpgrade(state, item))
        or (state.salvage.keepEffects and newEffect)
    if item.effect then
        state.discoveries["effect:" .. item.effect] = true
    end
    -- No inventory overflow loss: the shared inventory is not slot-limited.
    if keep then
        if not item.heirloom and not item.protected then
            for _, existing in ipairs(state.inventory) do
                if
                    not existing.protected
                    and not existing.heirloom
                    and G.SameItem(existing, item)
                    and existing.slot == item.slot
                    and existing.level == item.level
                    and existing.quality == item.quality
                    and existing.effect == item.effect
                    and (existing.upgrade or 0) == (item.upgrade or 0)
                then
                    existing.count = (existing.count or 1) + (item.count or 1)
                    return
                end
            end
        end
        state.inventory[#state.inventory + 1] = item
    else
        G.Salvage(state, item)
    end
end

function G.Equip(state, heroIndex, inventoryIndex)
    local hero, item = state.heroes[heroIndex], state.inventory[inventoryIndex]
    if
        not hero
        or not item
        or not C.slots[item.slot]
        or (item.itemID and not C.itemByID[item.itemID])
    then
        return false
    end
    if not item.heirloom and item.level > hero.level then
        return false, "This hero needs idle level " .. item.level .. "."
    end
    if state.guide.craftItem == item.uid then
        state.guide.craftItem, state.guide.craftHero = nil, nil
    end
    if (item.count or 1) > 1 then
        item.count = item.count - 1
        item = copy(item)
        item.count = nil
        item.uid = state.nextItem
        state.nextItem = state.nextItem + 1
    else
        table.remove(state.inventory, inventoryIndex)
    end
    local previous = hero.gear[item.slot]
    hero.gear[item.slot] = item
    state.guide.equipped = true
    G.Emit(state, "equip")
    G.RefreshHero(state, heroIndex)
    if previous then
        state.inventory[#state.inventory + 1] = previous
    end
    return true
end

function G.EquipBest(state, heroIndex)
    local hero = state.heroes[heroIndex]
    if not hero then
        return false, "Choose a hero."
    end
    local equipped = 0
    for _, slot in ipairs(C.equipmentSlots) do
        local bestIndex, bestPower = nil, G.ItemPower(hero.gear[slot], hero)
        for index, item in ipairs(state.inventory) do
            if item.slot == slot and (item.heirloom or item.level <= hero.level) then
                local power = G.ItemPower(item, hero)
                if power > bestPower then
                    bestIndex, bestPower = index, power
                end
            end
        end
        if bestIndex then
            G.Equip(state, heroIndex, bestIndex)
            equipped = equipped + 1
        end
    end
    return true,
        equipped > 0 and ("Equipped " .. equipped .. " upgrades on " .. hero.name .. ".")
            or (hero.name .. " already has the best available power equipment.")
end

function G.Cost(_, hero, heirloom)
    local level = heirloom and 1 or hero.level
    return {
        essence = heirloom and 45 or 4 + level * 2,
        gold = heirloom and 30 or level * 8,
        material = heirloom and 12 or 4 + level,
    }
end

-- Preview with a detached identity counter: inspecting recipes never changes the run.
function G.CraftItem(hero, slot, heirloom)
    if not hero or not C.slots[slot] then
        return nil, "Choose a hero and equipment slot."
    end
    local item = G.Item({ nextItem = 0 }, slot, heirloom and 1 or hero.level, 3, heirloom)
    if not item then
        return nil, "No equipment recipe is available for this slot."
    end
    if not heirloom and C.itemByID[item.itemID].level > hero.level then
        return nil, "Reach idle level " .. C.itemByID[item.itemID].level .. " to craft this slot."
    end
    return item
end

function G.CraftingOpportunity(state, heroIndex)
    local hero = state.heroes[heroIndex]
    if not hero then
        return
    end
    local best
    for mode = 1, 2 do
        local heirloom = mode == 2
        local cost = G.Cost(state, hero, heirloom)
        local material
        if state.essence >= cost.essence and state.gold >= cost.gold then
            for _, id in ipairs(C.materialOrder) do
                if state.materials[id] >= cost.material then
                    material = id
                    break
                end
            end
        end
        if material then
            if not best then
                best = {}
                for _, slot in ipairs(C.equipmentSlots) do
                    best[slot] = G.ItemPower(hero.gear[slot], hero)
                end
                for _, stored in ipairs(state.inventory) do
                    if best[stored.slot] and (stored.heirloom or stored.level <= hero.level) then
                        best[stored.slot] = math.max(best[stored.slot], G.ItemPower(stored, hero))
                    end
                end
            end
            for _, slot in ipairs(C.equipmentSlots) do
                if not heirloom or state.recipes[slot] then
                    local item = G.CraftItem(hero, slot, heirloom)
                    if item then
                        local power = G.ItemPower(item, hero)
                        if power > best[slot] then
                            return {
                                slot = slot,
                                material = material,
                                heirloom = heirloom,
                                item = item,
                            }
                        end
                    end
                end
            end
        end
    end
end

function G.Craft(state, index, slot, material, heirloom)
    local hero = state.heroes[index]
    if not hero or not C.slots[slot] or not C.materials[material] then
        return false, "Choose a hero, slot, and material."
    end
    if heirloom and not state.recipes[slot] then
        return false, "Unlock this heirloom recipe with Legacy first."
    end
    local cost = G.Cost(state, hero, heirloom)
    if
        state.essence < cost.essence
        or state.gold < cost.gold
        or state.materials[material] < cost.material
    then
        return false, "You need more Essence, gold, or materials."
    end
    local item, reason = G.CraftItem(hero, slot, heirloom)
    if not item then
        return false, reason
    end
    item.uid = state.nextItem
    state.nextItem = state.nextItem + 1
    state.essence = state.essence - cost.essence
    state.gold = state.gold - cost.gold
    state.materials[material] = state.materials[material] - cost.material
    state.inventory[#state.inventory + 1] = item
    if not state.guide.crafted then
        state.guide.crafted = true
        state.guide.craftItem, state.guide.craftHero = item.uid, index
    end
    G.Log(state, "Crafted " .. item.name .. " for " .. hero.name .. ".")
    G.Emit(state, "craft")
    return true
end

function G.UpgradeCost(item)
    local essence = 8 + (item.upgrade or 0) * 5
    return { essence = essence, gold = essence * 2 }
end

function G.Upgrade(state, index, slot)
    local hero = state.heroes[index]
    local item = hero and hero.gear[slot]
    if not item then
        return false, "Equip an item first."
    end
    local cost = G.UpgradeCost(item)
    if state.essence < cost.essence or state.gold < cost.gold then
        return false, "Need " .. cost.essence .. " Essence and " .. cost.gold .. " gold."
    end
    state.essence = state.essence - cost.essence
    state.gold = state.gold - cost.gold
    item.upgrade = (item.upgrade or 0) + 1
    G.Emit(state, "upgrade")
    G.RefreshHero(state, index)
    return true
end

function G.UnlockRecipe(state, slot)
    if not C.slots[slot] or state.recipes[slot] then
        return false, "Recipe already known."
    end
    if state.legacy < 1 then
        return false, "Earn Legacy by beginning a new chapter."
    end
    state.legacy = state.legacy - 1
    state.recipes[slot] = true
    G.Emit(state, "unlock")
    return true
end

-- Options only affect the view; indices always refer to the shared inventory.
function G.InventoryEntries(state, hero, slot, options)
    options = options or {}
    local entries = {}
    for index, item in ipairs(state.inventory) do
        local power = G.ItemPower(item, hero)
        local usable = item.heirloom or (hero and item.level <= hero.level)
        local upgrade = hero and power > G.ItemPower(hero.gear[item.slot], hero)
        local availability = options.availability
        local trait = options.trait
        if
            (not slot or slot == 0 or item.slot == slot)
            and (not options.quality or options.quality == 0 or item.quality == options.quality)
            and (not availability or availability == "all" or (availability == "usable" and usable) or (availability == "locked" and not usable) or (availability == "upgrades" and usable and upgrade))
            and (
                not trait
                or trait == "all"
                or (trait == "heirloom" and item.heirloom)
                or (trait == "protected" and item.protected)
                or (trait == "effect" and item.effect)
                or (trait == "upgraded" and (item.upgrade or 0) > 0)
            )
        then
            entries[#entries + 1] = { index = index, item = item, power = power }
        end
    end
    local sort = options.sort or "power"
    table.sort(entries, function(a, b)
        local av, bv = a.power, b.power
        if sort == "level" or sort == "quality" or sort == "slot" or sort == "name" then
            av, bv = a.item[sort], b.item[sort]
        end
        if av ~= bv then
            if options.ascending then
                return av < bv
            end
            return av > bv
        end
        return a.item.uid < b.item.uid
    end)
    return entries
end
