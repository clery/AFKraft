if not test then
    return
end

test("Live player models play once without per-frame timeline seeking", function()
    local client = WoWIdle.Client
    local starts, seeks = 0, 0
    local model = {
        nativeAppearance = true,
        appearanceUnit = "player",
        appearanceSource = {
            SetAnimation = function()
                starts = starts + 1
            end,
            SetSequenceTime = function()
                seeks = seeks + 1
            end,
        },
    }
    local played, speed = client.AnimateModel(model, 16, 1.1)
    assertTrue(played)
    assertEquals(1, speed)
    for frame = 1, 120 do
        client.AdvanceModelAnimation(model, frame / 120)
    end
    assertEquals(1, starts)
    assertEquals(0, seeks)
    client.AnimateModel(model, 25)
    assertEquals(2, starts)
end)

test("Passive damage does not create repeated weapon impacts", function()
    local effects = WoWIdle.UI.scene.effects
    local play = effects.Play
    local calls = 0
    effects.Play = function()
        calls = calls + 1
    end
    local unit = { melee = true }
    local units = { unit, unit, unit, unit, unit, unit }
    local state = { heroes = { { class = "ROGUE" } } }
    local ok, message = pcall(function()
        for _ = 1, 60 do
            effects:Event(units, state, {
                kind = "hit",
                source = 1,
                target = 1,
                enemy = true,
                passive = true,
            })
        end
        assertEquals(0, calls)
        effects:Event(units, state, { kind = "hit", source = 1, target = 1, enemy = true })
        assertEquals(1, calls)
    end)
    effects.Play = play
    assertTrue(ok, message)
end)
