local _, W = ...
local Scenery = {}
Scenery.__index = Scenery
W.Scenery = Scenery

function Scenery.Create(parent)
    local self = setmetatable({ actors = {}, supported = false }, Scenery)
    self.frame = CreateFrame("ModelScene", nil, parent)
    self.frame:SetAllPoints()
    self.frame:EnableMouse(false)
    -- Side view, with a horizontal stage and scenery behind the party.
    local ok, message = pcall(function()
        self.frame:SetCameraPosition(0, -24, 4)
        self.frame:SetCameraOrientationByAxisVectors(0, 1, 0, 1, 0, 0, 0, 0, 1)
        self.frame:SetCameraFieldOfView(0.55)
        self.frame:SetCameraNearClip(0.1)
        self.frame:SetCameraFarClip(200)
    end)
    if not ok then
        self.lastError = message
    end
    self.cameraReady = ok
    return self
end

function Scenery:SetZone(zoneID)
    if self.zone == zoneID then
        return
    end
    self.zone = zoneID
    if not self.cameraReady then
        return
    end
    local assets = W.Client.sceneryAssets[zoneID] or {}
    for _, actor in ipairs(self.actors) do
        actor:SetAlpha(0)
    end
    for i = 1, 6 do
        local id = assets[(i - 1) % math.max(1, #assets) + 1]
        if id then
            local ok, message = pcall(function()
                local actor = self.actors[i]
                if not actor then
                    actor = self.frame:CreateActor()
                    self.actors[i] = actor
                end
                if not actor.SetModelByFileID then
                    self.supported = false
                    self.lastError = "Scenery actor loading is unavailable in this renderer."
                    return
                end
                actor:SetModelByFileID(id)
                actor:SetPosition(-22 + (i - 1) * 9, 5 + (i % 2) * 3, -1)
                actor:SetScale(i % 3 == 0 and 0.28 or 0.45)
                actor:SetYaw(i * 0.7)
                actor:SetAlpha(1)
                self.supported = true
            end)
            if not ok then
                self.lastError = message
                self.supported = false
            end
        end
    end
end
