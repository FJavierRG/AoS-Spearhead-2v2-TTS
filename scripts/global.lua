-- Exported from TS_Save_4.json for review only.
-- TTS object: Global
-- GUID: global
-- Source of truth: embedded LuaScript inside TS_Save_4.json

redDiceMat_GUID = "c57d70"
blueDiceMat_GUID = "a84ed2"
redDiceRoller_GUID = "beae28"
blueDiceRoller_GUID = "4e0e0b"

-- ============================================================

-- ============================================================
-- DIAGNOSTICO
-- ============================================================
function onLoad()
    _removeResidualContainerSnapPoints()
    _assignSpearheadTeams()
    Wait.frames(function() _hideOverlayTemplates() end, 30)
end

function _removeResidualContainerSnapPoints()
    if not Global or not Global.getSnapPoints or not Global.setSnapPoints then return end

    local ok, snap_points = pcall(function() return Global.getSnapPoints() end)
    if not ok or type(snap_points) ~= "table" then return end

    local filtered = {}
    for _, snap in ipairs(snap_points) do
        local pos = snap.position or snap.Position
        local is_residual = pos
            and pos.x >= 18.0 and pos.x <= 25.5
            and pos.y >= 0.8 and pos.y <= 1.1
            and pos.z >= -10.5 and pos.z <= -3.0

        if not is_residual then
            table.insert(filtered, snap)
        end
    end

    if #filtered ~= #snap_points then
        pcall(function() Global.setSnapPoints(filtered) end)
    end
end

function onPlayerChangeColor(player_color)
    Wait.frames(function() _assignSpearheadTeams() end, 1)
end

function _assignSpearheadTeams()
    local assignments = {
        Red = "Hearts",
        Pink = "Hearts",
        Blue = "Clubs",
        Teal = "Clubs"
    }

    for color, team in pairs(assignments) do
        if Player[color] ~= nil then
            Player[color].team = team
        end
    end
end

function onChat(message, player)
    if message == "test" then
    elseif message == "spawn" then
        _spawnOverlay("a5109b", 2)
    elseif message == "despawn" then
        _despawnAllOverlays()
    elseif message == "hide" then
        _hideOverlayTemplates()
    elseif message == "showbtn" then
        for g, t in pairs(overlayButtons) do
            local o = getObjectFromGUID(g)
            local present = (o ~= nil) and "OK" or "MISSING"
        end
    end
    return false
end


-- 2v2 overlays via clone (refactor)
-- ============================================================
-- Los botones (a5109b etc.) son objetos puros sin States. Al pulsar 1/2/3
-- sobre uno, este callback clona la plantilla correspondiente (oculta en
-- y=-100) y la posiciona/escala donde queramos. Toggle: misma tecla destruye.

overlayButtons = {
    ["a5109b"] = "territory",
    ["9b180a"] = "territory",
    ["9fe02b"] = "terrain",
    ["4a1317"] = "terrain",
    ["bd190b"] = "deployment",
    ["a2056b"] = "deployment",
    ["abb564"] = "edges",
}

overlayTemplates = {
    ["a5109b"] = {
        [2] = "a5d951",
        [3] = "cefcd9",
    },
    ["9b180a"] = {
        [2] = "765d58",
        [3] = "0d990f",
    },
    ["9fe02b"] = {
        [2] = "ebd1b3",
        [3] = "595a07",
    },
    ["4a1317"] = {
        [2] = "24bc1f",
        [3] = "ac093c",
    },
    ["bd190b"] = {
        [2] = "eaa9a7",
        [3] = "7b966f",
    },
    ["a2056b"] = {
        [2] = "bdcfc7",
        [3] = "4aa032",
    },
    ["abb564"] = {
        [3] = "ca0974",
        [4] = "34239c",
        [2] = "da1bc4",
    },
}

overlayTypeZ = {
    ["territory"] = 15.94,
    ["terrain"] = 11.95,
    ["deployment"] = 5.32,
    ["edges"] = 0.0,
}

OVERLAY_SPAWN_X = 34.12
OVERLAY_CENTER_X = 5.0   -- centro X del tablero combinado, para compensar flip
OVERLAY_SPAWN_Y = 0.89
OVERLAY_SCALE   = {x = 0.896, y = 0.6, z = 0.797}
OVERLAY_ROT     = {x = 0, y = 0, z = 180.0}

-- Override de scale por tipo (si difiere del default OVERLAY_SCALE)
overlayScaleOverride = {
    ["terrain"] = {x = 0.896, y = 0.6, z = 0.896},
}

-- Override de rotacion por tipo. Estados triangulares (2 y 3) de
-- territory/terrain/deployment requieren orientacion distinta de la base.
overlayRotOverride = {
    -- vacio por ahora; usa OVERLAY_ROT por defecto.
}

-- Flip horizontal por btype + state. scaleX se vuelve negativo para
-- reflejar el triangulo en el eje X manteniendo la cara hacia arriba.
overlayFlipX = {
    ["territory"]  = {},
    ["terrain"]    = {},
    ["deployment"] = {},
}

-- Override de scale por btype + state (mas fino que overlayScaleOverride)
overlayScaleByState = {
    ["territory"] = {
        -- Territory 2v2 usa meshes locales centrados en el tablero.
        [2] = {x = 1.0, y = 1.0, z = 2.01},
    },
    ["terrain"] = {
        -- Terrain 2v2 usa meshes locales centrados; vertices ya estan en unidades TTS.
        [2] = {x = 1.0, y = 1.0, z = 1.0},
    },
    ["deployment"] = {
        -- Deployment 2v2 usa meshes locales centrados; vertices ya estan en unidades TTS.
        [2] = {x = 1.0, y = 1.0, z = 1.98},
    },
}

-- Override de posX por btype + state (sustituye al target_x automatico)
overlayPosXByState = {
    ["territory"] = {
        -- Centro real del tablero 2v2 medido ingame.
        [2] = 4.99,
    },
    ["terrain"] = {
        -- Centro real del tablero 2v2 medido ingame.
        [2] = 4.99,
    },
    ["deployment"] = {
        -- Centro real del tablero 2v2 medido ingame.
        [2] = 4.99,
    },
}

-- Override de posZ por btype + state (sustituye a overlayTypeZ)
overlayPosZByState = {
    ["territory"] = {
        -- Centro real del tablero 2v2 medido ingame.
        [2] = 0.07,
    },
    ["terrain"] = {
        -- Centro real del tablero 2v2 medido ingame.
        [2] = 0.07,
    },
    ["deployment"] = {
        -- Centro real del tablero 2v2 medido ingame.
        [2] = 0.07,
    },
}




activeOverlayByCategory = activeOverlayByCategory or {}  -- category -> {obj, button_guid, state_num}

function _despawnCategory(category)
    local entry = activeOverlayByCategory[category]
    if not entry then return end
    if entry.obj and entry.obj.destruct then entry.obj.destruct() end
    activeOverlayByCategory[category] = nil
end

function _spawnOverlay(button_guid, state_num)
    local btype = overlayButtons[button_guid]
    if not btype then
        return
    end
    local templates = overlayTemplates[button_guid]
    if not templates then
        return
    end
    local tg = templates[state_num]
    if not tg then
        return
    end
    local tmpl = getObjectFromGUID(tg)
    if not tmpl then
        return
    end
    -- Garantizar que la categoria queda limpia antes de spawnear
    _despawnCategory(btype)
    local z = overlayTypeZ[btype] or 0
    local z_override = overlayPosZByState and overlayPosZByState[btype] and overlayPosZByState[btype][state_num]
    if z_override then z = z_override end
    local target_x
    local pos_override = overlayPosXByState and overlayPosXByState[btype] and overlayPosXByState[btype][state_num]
    if pos_override then
        target_x = pos_override
    elseif overlayFlipX and overlayFlipX[btype] and overlayFlipX[btype][state_num] then
        target_x = 2 * OVERLAY_CENTER_X - OVERLAY_SPAWN_X
    else
        target_x = OVERLAY_SPAWN_X
    end
    local copy = tmpl.clone({
        position = {x = target_x, y = OVERLAY_SPAWN_Y, z = z}
    })
    -- Registrar la entrada inmediatamente con la referencia al objeto recien clonado
    activeOverlayByCategory[btype] = {obj = copy, button_guid = button_guid, state_num = state_num}
    Wait.frames(function()
        if copy then
            local base_scale = (overlayScaleByState and overlayScaleByState[btype] and overlayScaleByState[btype][state_num])
                or (overlayScaleOverride and overlayScaleOverride[btype])
                or OVERLAY_SCALE
            local sx = base_scale.x
            if overlayFlipX and overlayFlipX[btype] and overlayFlipX[btype][state_num] then
                sx = -math.abs(base_scale.x)
            end
            local scale = {x = sx, y = base_scale.y, z = base_scale.z}
            copy.setScale(scale)
            local rot = (overlayRotOverride and overlayRotOverride[btype]) or OVERLAY_ROT
            copy.setRotation(rot)
            copy.setPosition({x = target_x, y = OVERLAY_SPAWN_Y, z = z})
            copy.setLock(true)
            copy.interactable = false
            copy.setInvisibleTo({})
        else
            activeOverlayByCategory[btype] = nil
        end
    end, 2)
end

-- onObjectNumberTyped intencionalmente eliminado: los botones gestionan sus
-- pulsaciones via onNumberTyped local que invoca Global._handleOverlayInput.

-- Limpieza al cambiar de pack/realm
function _despawnAllOverlays()
    for cat, _ in pairs(activeOverlayByCategory) do _despawnCategory(cat) end
end


function _handleOverlayInput(params)
    local g = params.guid
    local number = params.number
    local category = overlayButtons[g]
    if not category then
        return
    end

    -- Regla 1: el 1 SIEMPRE limpia la categoria entera y no spawnea nada.
    if number == 1 then
        _despawnCategory(category)
        return
    end

    -- Regla 2: si el overlay activo coincide en boton y state, toggle (despawn).
    local entry = activeOverlayByCategory[category]
    if entry and entry.button_guid == g and entry.state_num == number then
        _despawnCategory(category)
        return
    end

    -- Regla 3: cualquier otro caso => limpiar categoria y spawnear el nuevo.
    _spawnOverlay(g, number)
end


function _hideOverlayTemplates()
    local guids = {"a5d951","cefcd9","765d58","0d990f","ebd1b3","595a07","24bc1f","ac093c","eaa9a7","7b966f","bdcfc7","4aa032","ca0974","34239c","da1bc4"}
    for _, g in ipairs(guids) do
        local o = getObjectFromGUID(g)
        if o then
            o.setInvisibleTo({"Red","Blue","Green","Yellow","Orange","Purple","Black","White","Brown","Pink","Grey","Teal"})
            o.interactable = false
            o.setLock(true)
        end
    end
end
