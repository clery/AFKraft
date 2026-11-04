local _, W = ...
local C, G = W.Content, W.Game
local copy = G.Copy

function G.ItemArmorType(item)
    if not item or item.slot == 1 or item.slot == 4 then
        return nil
    end
    local template = C.itemByID[item.itemID]
    -- Older synthetic armor had no subclass; treat it as cloth rather than losing it.
    return template and template.armorType or item.armorType or "cloth"
end

function G.CanWearArmor(hero, item)
    if not hero or not item or not C.slots[item.slot] then
        return false, "Choose a hero and equipment item."
    end
    local armorType = G.ItemArmorType(item)
    if not armorType then
        return true
    end
    local rank, proficiency = C.armorRanks[armorType], C.classArmor[hero.class]
    local maximum = proficiency and proficiency[hero.level >= 40 and 2 or 1]
    if not rank or not maximum or rank > maximum then
        if proficiency and rank and rank > proficiency[1] and rank <= proficiency[2] then
            return false, "This hero needs idle level 40 to wear " .. C.armorNames[armorType] .. "."
        end
        return false, "This class cannot wear " .. (C.armorNames[armorType] or "this armor") .. "."
    end
    return true
end

function G.ItemWeaponType(item)
    if not item or item.slot ~= 1 then
        return nil
    end
    local template = C.itemByID[item.itemID]
    return template and template.weaponType or item.weaponType
end

function G.CanUseWeapon(hero, item)
    if not hero or not item or not C.slots[item.slot] then
        return false, "Choose a hero and equipment item."
    end
    if item.slot ~= 1 then
        return true
    end
    local weaponType = G.ItemWeaponType(item)
    local proficiency = C.classWeapons[hero.class]
    if not weaponType or not proficiency or not proficiency[weaponType] then
        return false,
            "This class cannot use " .. (C.weaponNames[weaponType] or "this weapon") .. "."
    end
    return true
end

function G.CanEquip(hero, item)
    local allowed, reason = G.CanWearArmor(hero, item)
    if not allowed then
        return false, reason
    end
    allowed, reason = G.CanUseWeapon(hero, item)
    if not allowed then
        return false, reason
    end
    if not item.heirloom and item.level > hero.level then
        return false, "This hero needs idle level " .. item.level .. "."
    end
    return true
end

-- Keep purchased enhancements and identities when enforcing new restrictions or resetting levels.
function G.ReturnUnusableGear(state, hero)
    local changed = false
    for slot, item in pairs(hero.gear or {}) do
        if not G.CanEquip(hero, item) then
            state.inventory[#state.inventory + 1] = item
            hero.gear[slot] = nil
            changed = true
        end
    end
    return changed
end

-- Generic generation chooses the closest entry; crafting supplies a class-compatible template.
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
    if (a.forge or 0) ~= (b.forge or 0) or (a.forgePower or 0) ~= (b.forgePower or 0) then
        return false
    end
    if
        (a.enchant and a.enchant.id) ~= (b.enchant and b.enchant.id)
        or (a.enchant and a.enchant.level) ~= (b.enchant and b.enchant.level)
    then
        return false
    end
    for _, key in ipairs(C.itemStatOrder) do
        if
            (a.enchant and a.enchant.stats[key] or 0) ~= (b.enchant and b.enchant.stats[key] or 0)
        then
            return false
        end
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
            G.CanEquip(hero, item)
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

-- Manual disenchanting uses item identity so a refreshed/sorted view cannot destroy a neighbor.
function G.DisenchantReward(item, quantity)
    if not item or item.heirloom or item.protected or not C.slots[item.slot] then
        return nil
    end
    local count = item.count or 1
    if
        type(count) ~= "number"
        or count < 1
        or count == math.huge
        or count ~= math.floor(count)
        or type(item.level) ~= "number"
        or item.level < 1
        or item.level == math.huge
        or item.level ~= math.floor(item.level)
        or type(item.quality) ~= "number"
        or not C.qualityNames[item.quality]
    then
        return nil
    end
    if quantity ~= nil then
        if quantity ~= 1 and quantity ~= 10 and quantity ~= 100 then
            return nil
        end
        count = math.min(count, quantity)
    end
    return {
        gold = math.floor(item.level * item.quality) * count,
        relic = math.max(1, item.quality - 1) * count,
        count = count,
    }
end

function G.Disenchant(state, item, quantity)
    local reward = G.DisenchantReward(item, quantity)
    if not reward then
        return false, "Heirlooms and protected items cannot be disenchanted."
    end
    for index, stored in ipairs(state.inventory) do
        if stored == item then
            local remaining = (item.count or 1) - reward.count
            if remaining > 0 then
                item.count = remaining
            else
                table.remove(state.inventory, index)
            end
            state.gold = state.gold + reward.gold
            state.materials.relic = state.materials.relic + reward.relic
            state.stats.salvaged = state.stats.salvaged + reward.count
            if remaining == 0 and state.guide.craftItem == item.uid then
                state.guide.craftItem, state.guide.craftHero = nil, nil
            end
            local message = "Disenchanted "
                .. item.name
                .. " x"
                .. reward.count
                .. " · +"
                .. reward.gold
                .. " gold, +"
                .. reward.relic
                .. " Relic dust."
            G.Log(state, message)
            return true, message
        end
    end
    return false, "This item is no longer in the shared inventory."
end

-- Bulk actions intentionally cover the shared inventory, independent of view filters.
function G.DisenchantAllReward(state)
    local total = { gold = 0, relic = 0, count = 0 }
    for _, item in ipairs(state.inventory) do
        local reward = G.DisenchantReward(item)
        if reward then
            for key, value in pairs(reward) do
                total[key] = total[key] + value
            end
        end
    end
    return total
end

function G.DisenchantAll(state)
    local total = G.DisenchantAllReward(state)
    if total.count == 0 then
        return false, "No unprotected equipment to disenchant."
    end
    for index = #state.inventory, 1, -1 do
        local item = state.inventory[index]
        if G.DisenchantReward(item) then
            table.remove(state.inventory, index)
            if state.guide.craftItem == item.uid then
                state.guide.craftItem, state.guide.craftHero = nil, nil
            end
        end
    end
    state.gold = state.gold + total.gold
    state.materials.relic = state.materials.relic + total.relic
    state.stats.salvaged = state.stats.salvaged + total.count
    local message = "Disenchanted "
        .. total.count
        .. " items · +"
        .. total.gold
        .. " gold, +"
        .. total.relic
        .. " Relic dust."
    G.Log(state, message)
    return true, message
end

function G.Loot(state, item)
    if item.quality >= 3 then
        G.Emit(state, "loot")
    end
    local newEffect = item.effect and not state.discoveries["effect:" .. item.effect]
    local keep = item.heirloom
        or G.KeepByLootPolicy(state, item)
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

function G.SetLootPolicy(state, key, value)
    if key == "class" then
        if value ~= "any" and not C.classByID[value] then
            return false, "Choose a class."
        end
    elseif key == "slot" then
        if value ~= 0 and not C.slots[value] then
            return false, "Choose an equipment slot."
        end
    elseif key == "stat" then
        if value ~= "any" and not C.itemStatNames[value] then
            return false, "Choose an item stat."
        end
    else
        return false, "Unknown loot policy."
    end
    state.salvage.policy[key] = value
    return true
end

function G.KeepByLootPolicy(state, item)
    local policy = state.salvage.policy
    if not policy or (policy.class == "any" and policy.slot == 0 and policy.stat == "any") then
        return false
    end
    if policy.slot ~= 0 and policy.slot ~= item.slot then
        return false
    end
    if policy.class ~= "any" then
        local hero = { class = policy.class, level = C.heroLevelCap }
        if not G.CanEquip(hero, item) then
            return false
        end
    end
    return policy.stat == "any" or (G.ItemStats(item)[policy.stat] or 0) > 0
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
    local allowed, reason = G.CanEquip(hero, item)
    if not allowed then
        return false, reason
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
            if item.slot == slot and G.CanEquip(hero, item) then
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

function G.Cost(state, hero, heirloom)
    local level = heirloom and 1 or hero.level
    local discount = state.professions and G.ProfessionModifiers(state, "crafting").costMultiplier
        or 1
    discount = discount * (state.development and G.DevelopmentModifiers(state).costMultiplier or 1)
    return {
        essence = 0,
        gold = math.max(1, math.ceil((heirloom and 30 or level * 8) * discount)),
        -- Even full discounts consume more material than the maximum four Ore
        -- returned by salvaging a crafted item, preventing a closed profit loop.
        material = math.max(5, math.ceil((heirloom and 12 or 4 + math.ceil(level / 4)) * discount)),
    }
end

-- Preview with a detached identity counter: inspecting recipes never changes the run.
function G.CraftItem(hero, slot, heirloom, state)
    if not hero or not C.slots[slot] then
        return nil, "Choose a hero and equipment slot."
    end
    local template, bestPower
    for _, candidate in ipairs(C.items) do
        if
            candidate.slot == slot
            and G.CanWearArmor(hero, candidate)
            and G.CanUseWeapon(hero, candidate)
            and (heirloom or candidate.level <= hero.level)
        then
            local power = G.ItemPower(
                heirloom and { itemID = candidate.itemID, stats = candidate.stats, heirloom = true }
                    or candidate,
                hero
            )
            if not bestPower or power > bestPower then
                template, bestPower = candidate, power
            end
        end
    end
    if not template then
        return nil, "No usable equipment recipe is available for this hero and slot."
    end
    local item = G.Item({ nextItem = 0 }, slot, heirloom and 1 or hero.level, 3, heirloom, template)
    if not item then
        return nil, "This equipment recipe is unavailable."
    end
    if state then
        local modifiers = G.ProfessionModifiers(state, "crafting")
        for stat, value in pairs(item.stats) do
            item.stats[stat] = value * modifiers.statMultiplier
        end
        item.quality = math.min(4, item.quality + modifiers.qualityBonus)
    end
    item.crafted = true
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
        if state.gold >= cost.gold then
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
                    if best[stored.slot] and G.CanEquip(hero, stored) then
                        best[stored.slot] = math.max(best[stored.slot], G.ItemPower(stored, hero))
                    end
                end
            end
            for _, slot in ipairs(C.equipmentSlots) do
                if not heirloom or state.recipes[slot] then
                    local item = G.CraftItem(hero, slot, heirloom, state)
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
        return false, "Unlock this heirloom recipe with Heritage first."
    end
    local cost = G.Cost(state, hero, heirloom)
    if state.gold < cost.gold or state.materials[material] < cost.material then
        return false, "You need more gold or idle materials."
    end
    local item, reason = G.CraftItem(hero, slot, heirloom, state)
    if not item then
        return false, reason
    end
    item.uid = state.nextItem
    state.nextItem = state.nextItem + 1
    state.gold = state.gold - cost.gold
    state.materials[material] = state.materials[material] - cost.material
    state.inventory[#state.inventory + 1] = item
    G.ProfessionWork(state, "crafting")
    if not state.guide.crafted then
        state.guide.crafted = true
        state.guide.craftItem, state.guide.craftHero = item.uid, index
    end
    G.Log(state, "Crafted " .. item.name .. " for " .. hero.name .. ".")
    G.Emit(state, "craft")
    return true
end

function G.UpgradeCost(item, state)
    local rank = item.upgrade or 0
    local discount = state and state.development and G.DevelopmentModifiers(state).costMultiplier
        or 1
    return {
        essence = 0,
        gold = math.max(1, math.ceil((16 + rank * 10 + rank * rank * 6) * discount)),
        materials = { ore = math.max(1, math.ceil((2 + rank) * discount)) },
    }
end

function G.Upgrade(state, index, slot)
    local hero = state.heroes[index]
    local item = hero and hero.gear[slot]
    if not item then
        return false, "Equip an item first."
    end
    local cost = G.UpgradeCost(item, state)
    if state.gold < cost.gold or state.materials.ore < cost.materials.ore then
        return false, "Need " .. cost.gold .. " gold and " .. cost.materials.ore .. " Ore."
    end
    state.gold = state.gold - cost.gold
    state.materials.ore = state.materials.ore - cost.materials.ore
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
        return false, "Earn Heritage by beginning a new chapter."
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
        local usable = G.CanEquip(hero, item)
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
