local _, W = ...
local Backdrop = {}
Backdrop.__index = Backdrop
W.Backdrop = Backdrop

function Backdrop.Create(parent)
    local self = setmetatable({ parent = parent, supported = false }, Backdrop)
    -- Keep the screenshot in the stage's background layer, below labels and
    -- character models. An opaque child frame would cover the stage's text.
    self.image = parent:CreateTexture(nil, "BACKGROUND", nil, 1)
    self.image:SetAllPoints()

    self.header = parent:CreateTexture(nil, "ARTWORK", nil, -7)
    self.header:SetPoint("TOPLEFT")
    self.header:SetPoint("TOPRIGHT")
    self.header:SetHeight(88)
    self.header:SetColorTexture(0, 0, 0, 0.40)

    self.footer = parent:CreateTexture(nil, "ARTWORK", nil, -7)
    self.footer:SetPoint("BOTTOMLEFT")
    self.footer:SetPoint("BOTTOMRIGHT")
    self.footer:SetHeight(76)
    self.footer:SetColorTexture(0, 0, 0, 0.60)
    return self
end

function Backdrop:SetZone(zoneID)
    local aspect = self.parent:GetWidth() / self.parent:GetHeight()
    if self.zone == zoneID and self.aspect == aspect then
        return
    end
    self.zone = zoneID
    self.aspect = aspect
    local texture = W.Content.backdrops[zoneID]
    self.supported = texture ~= nil
    if texture then
        self.lastError = nil
    else
        self.lastError = "No screenshot is configured for this destination."
    end
    self.image:SetShown(self.supported)
    self.header:SetShown(self.supported)
    self.footer:SetShown(self.supported)
    if not texture then
        return
    end
    self.image:SetTexture(texture)
    -- All packaged textures are 4:1. Crop rather than stretch the landscape.
    if aspect < 4 then
        local margin = (1 - aspect / 4) / 2
        self.image:SetTexCoord(margin, 1 - margin, 0, 1)
    else
        local margin = (1 - 4 / aspect) / 2
        self.image:SetTexCoord(0, 1, margin, 1 - margin)
    end
end
