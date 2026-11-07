if not test then
    return
end

test("Live player models play once without per-frame timeline seeking", function()
    local client = AFKraft.Client
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
    local effects = AFKraft.UI.scene.effects
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

test("Cast hand effects attach once to the visible model with client and API fallbacks", function()
    local client = AFKraft.Client
    local flavor = client.flavor
    local calls, lastKit = 0, nil
    local function apply(_, kit, oneShot)
        assertTrue(oneShot)
        calls, lastKit = calls + 1, kit
    end
    local ok, message = pcall(function()
        client.flavor = "retail"
        local actor = { SetSpellVisualKit = apply }
        for class, kit in pairs({
            MAGE = 194,
            WARLOCK = 114,
            SHAMAN = 124,
            DRUID = 3290,
            PRIEST = 184,
            PALADIN = 99,
        }) do
            assertTrue(client.PlayCastEffect({ adventureActor = actor }, class))
            assertEquals(kit, lastKit)
        end
        assertEquals(6, calls)
        assertTrue(client.PlayCastEffect({
            nativeAppearance = true,
            appearanceSource = { ApplySpellVisualKit = apply },
            adventureActor = actor,
        }, "MAGE"))
        assertEquals(7, calls)
        assertFalse(client.PlayCastEffect({}, "MAGE"))
        assertFalse(client.PlayCastEffect({ adventureActor = actor }, "WARRIOR"))
        client.flavor = "forever"
        assertTrue(client.PlayCastEffect({ adventureActor = actor }, "MAGE"))
        assertEquals(8, calls)
    end)
    client.flavor = flavor
    assertTrue(ok, message)
end)

test(
    "Forever human priests enable hand particles on their visible model and Smite hits the target",
    function()
        local W = AFKraft
        local client, effects = W.Client, W.UI.scene.effects
        local flavor, play = client.flavor, effects.Play
        local particleEnabled, kit, kind, source, target
        local priest = { melee = false }
        local enemy = {}
        local ok, message = pcall(function()
            client.flavor = "forever"
            assertTrue(client.PlayCastEffect({
                nativeAppearance = true,
                appearanceSource = {
                    SetParticlesEnabled = function(_, enabled)
                        particleEnabled = enabled
                    end,
                    ApplySpellVisualKit = function(_, id, oneShot)
                        assertTrue(particleEnabled and oneShot)
                        kit = id
                    end,
                },
            }, "PRIEST"))
            assertEquals(184, kit)
            effects.Play = function(_, from, to, effect)
                source, target, kind = from, to, effect
            end
            effects:Event(
                { priest, nil, nil, nil, nil, enemy },
                { heroes = { { class = "PRIEST" } } },
                {
                    kind = "hit",
                    source = 1,
                    target = 1,
                    enemy = true,
                }
            )
            assertEquals(priest, source)
            assertEquals(enemy, target)
            assertEquals("smite", kind)
            assertEquals(166354, client.SpellEffectSpec(kind, "PRIEST").fileID)
            assertEquals(166360, client.SpellEffectSpec("shield", "PRIEST").fileID)
            assertEquals(nil, client.SpellEffectSpec("bolt", "MAGE"))
            client.flavor = "retail"
            assertEquals(166354, client.SpellEffectSpec("smite", "PRIEST").fileID)
        end)
        client.flavor, effects.Play = flavor, play
        assertTrue(ok, message)
    end
)

test(
    "Caster hand effects start before the cast animation and do not replay on later frames",
    function()
        local W = AFKraft
        local state = W.Game.New(W.Client.Now())
        W.Game.AddHero(state, "PRIEST")
        W.state = state
        W.Game.StartBattle(state)
        W.UI:SetTab("adventure")
        local scene = W.UI.scene
        scene:Refresh(state)
        local unit = scene.units[1]
        unit.x, unit.y = unit.combatant.x, unit.combatant.y
        unit.velocityX, unit.velocityY = 0, 0
        unit.modelReady, unit.moving, unit.travelling = true, false, false
        local animate, effect = W.Client.AnimateModel, W.Client.PlayCastEffect
        local order = {}
        W.Client.PlayCastEffect = function(model, class)
            assertEquals(unit.model, model)
            assertEquals("PRIEST", class)
            order[#order + 1] = "hands"
            return true
        end
        W.Client.AnimateModel = function(model, animation)
            if model == unit.model and animation == 53 then
                order[#order + 1] = "cast"
            end
            return true, 1
        end
        local ok, message = pcall(function()
            unit.pendingAnimation = 53
            scene:Animate()
            assertEquals("hands", order[1])
            assertEquals("cast", order[2])
            scene:Animate()
            W.Scene.FinishAnimation(unit)
            assertEquals(2, #order)
        end)
        W.Client.AnimateModel, W.Client.PlayCastEffect = animate, effect
        assertTrue(ok, message)
    end
)
