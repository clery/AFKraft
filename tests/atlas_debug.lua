test("Pin calibration is session-only and drafts cannot affect ordinary travel", function()
    local W = WoWIdle
    W.Initialize()
    local D = W.AtlasPinDebug
    assertFalse(D.enabled)
    local debugOptions = W.settingsOptions.args.debug.args
    assertFalse(debugOptions.pinCalibration.get())
    assertTrue(debugOptions.exportPins.disabled())
    W.UI:SetTab("atlas")
    local originalX, originalY = W.Client.ZonePosition("durotar", "kalimdor")
    local previous = W.state.ui.pinCalibration
    W.state.ui.pinCalibration = { durotar = { continent = "kalimdor", x = 0.6, y = 0.49 } }
    assertEquals(originalX, W.Client.ZonePosition("durotar", "kalimdor"))
    debugOptions.pinCalibration.set(nil, true)
    assertTrue(D.enabled)
    assertEquals(0.6, W.Client.ZonePosition("durotar", "kalimdor"))
    local pin = W.UI.atlas.maps[1].pins.durotar
    local destination = W.state.zone
    pin:GetScript("OnClick")(pin)
    assertEquals(destination, W.state.zone)
    assertTrue(D.ExportText():find("0.600000, 0.490000", 1, true) ~= nil)
    debugOptions.pinCalibration.set(nil, false)
    assertFalse(D.enabled)
    local x, y = W.Client.ZonePosition("durotar", "kalimdor")
    assertEquals(originalX, x)
    assertEquals(originalY, y)
    assertFalse(W.UI.atlas.calibrationNote:IsShown())
    assertTrue(W.state.ui.pinCalibration.durotar ~= nil)
    W.state.ui.pinCalibration = previous
end)
