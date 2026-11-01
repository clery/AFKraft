local _, W = ...
local A = W.Client

function A.EquipmentSpec(hero)
    local equipment, key = {}, {}
    for _, slot in ipairs(W.Content.equipmentSlots) do
        local item = type(hero.gear) == "table" and hero.gear[slot]
        local id = type(item) == "table" and item.itemID
        local template = id and W.Content.itemByID[id]
        if template then
            equipment[#equipment + 1] = id
            key[#key + 1] = slot .. "=" .. id
        end
    end
    return equipment, table.concat(key, ";")
end

function A.ApplyModelEquipment(model, spec)
    if not spec.equipment or model.equipmentAppliedKey == spec.equipmentKey then
        return true
    end
    local source = model.appearanceSource
    if source.IsGeoReady and not source:IsGeoReady() then
        return false
    end
    -- Set before dressing: texture/geometry callbacks can run synchronously.
    model.equipmentAppliedKey = spec.equipmentKey
    model.equipmentErrors = {}
    source:Undress()
    for _, id in ipairs(spec.equipment) do
        local cached = not C_Item
            or not C_Item.IsItemDataCachedByID
            or C_Item.IsItemDataCachedByID(id)
        if not cached and C_Item.RequestLoadItemDataByID then
            model.pendingEquipment = model.pendingEquipment or {}
            if not model.pendingEquipment[id] then
                model.pendingEquipment[id] = true
                C_Item.RequestLoadItemDataByID(id)
            end
        else
            -- Strings are physical item IDs; numeric TryOn arguments are appearance IDs.
            local ok, message = pcall(source.TryOn, source, "item:" .. id)
            if not ok then
                model.equipmentErrors[id] = message
            end
        end
    end
    return true
end
