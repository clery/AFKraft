local _, W = ...
-- Zone screenshot paths. Credits: Assets/Backdrops/SOURCES.md.
W.Content.backdrops = {
    elwynn = "Interface\\AddOns\\WoWIdle\\Assets\\Backdrops\\elwynn.tga",
    durotar = "Interface\\AddOns\\WoWIdle\\Assets\\Backdrops\\durotar.tga",
    westfall = "Interface\\AddOns\\WoWIdle\\Assets\\Backdrops\\westfall.tga",
    barrens = "Interface\\AddOns\\WoWIdle\\Assets\\Backdrops\\barrens.tga",
    redridge = "Interface\\AddOns\\WoWIdle\\Assets\\Backdrops\\redridge.tga",
    ashenvale = "Interface\\AddOns\\WoWIdle\\Assets\\Backdrops\\ashenvale.tga",
    duskwood = "Interface\\AddOns\\WoWIdle\\Assets\\Backdrops\\duskwood.tga",
    wetlands = "Interface\\AddOns\\WoWIdle\\Assets\\Backdrops\\wetlands.tga",
    stranglethorn = "Interface\\AddOns\\WoWIdle\\Assets\\Backdrops\\stranglethorn.tga",
    desolace = "Interface\\AddOns\\WoWIdle\\Assets\\Backdrops\\desolace.tga",
    tanaris = "Interface\\AddOns\\WoWIdle\\Assets\\Backdrops\\tanaris.tga",
    winterspring = "Interface\\AddOns\\WoWIdle\\Assets\\Backdrops\\winterspring.tga",
}

-- Temporary shared landscapes until destination-specific screenshots are available.
W.Content.backdrops.dun_morogh = W.Content.backdrops.winterspring
W.Content.backdrops.teldrassil = W.Content.backdrops.ashenvale
W.Content.backdrops.mulgore = W.Content.backdrops.barrens
W.Content.backdrops.tirisfal = W.Content.backdrops.duskwood
W.Content.backdrops.loch_modan = W.Content.backdrops.redridge
W.Content.backdrops.darkshore = W.Content.backdrops.ashenvale
W.Content.backdrops.silverpine = W.Content.backdrops.duskwood
W.Content.backdrops.stonetalon = W.Content.backdrops.ashenvale
W.Content.backdrops.hillsbrad = W.Content.backdrops.redridge
W.Content.backdrops.thousand_needles = W.Content.backdrops.desolace
W.Content.backdrops.alterac = W.Content.backdrops.winterspring
W.Content.backdrops.arathi = W.Content.backdrops.redridge
W.Content.backdrops.badlands = W.Content.backdrops.desolace
W.Content.backdrops.swamp_sorrows = W.Content.backdrops.wetlands
W.Content.backdrops.dustwallow = W.Content.backdrops.wetlands
W.Content.backdrops.feralas = W.Content.backdrops.stranglethorn
W.Content.backdrops.hinterlands = W.Content.backdrops.ashenvale
W.Content.backdrops.azshara = W.Content.backdrops.redridge
W.Content.backdrops.searing_gorge = W.Content.backdrops.desolace
W.Content.backdrops.blasted_lands = W.Content.backdrops.durotar
W.Content.backdrops.felwood = W.Content.backdrops.duskwood
W.Content.backdrops.ungoro = W.Content.backdrops.stranglethorn
W.Content.backdrops.burning_steppes = W.Content.backdrops.durotar
W.Content.backdrops.western_plaguelands = W.Content.backdrops.duskwood
W.Content.backdrops.deadwind = W.Content.backdrops.duskwood
W.Content.backdrops.eastern_plaguelands = W.Content.backdrops.duskwood
W.Content.backdrops.silithus = W.Content.backdrops.tanaris
W.Content.backdrops.moonglade = W.Content.backdrops.ashenvale
W.Content.backdrops.blackrock_mountain = W.Content.backdrops.durotar
