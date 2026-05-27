-- Exported from TS_Save_4.json for review only.
-- TTS object: Spearhead Scoresheet
-- GUID: 814d2d
-- Source of truth: embedded LuaScript inside TS_Save_4.json

-- ----------------------------
-- GLOBALS & DEFAULT STATE
-- ----------------------------
local STATE_VERSION = 1

buttonStates = buttonStates or {}
sheetData    = sheetData or {
    alliance1   = "Grand Alliance",
    spearhead1  = "Spearhead",
    alliance2   = "Grand Alliance",
    spearhead2  = "Spearhead",
    gamingPack  = "Fire & Jade",
    realm       = "Aqshy",
    totalScore1 = 0,
    totalScore2 = 0
}

spawnedTerrain      = spawnedTerrain or {}
spawnedBattleDecks  = spawnedBattleDecks or {}
spawnedDeck         = spawnedDeck or nil
restoringFromSave = restoringFromSave or false


-- Tag used to mark tactic decks / mini-decks
local TACTIC_TAG = "__TACTIC__"
local tacticDeckGuids = {}

local function _refreshTacticWhitelist()
    tacticDeckGuids = {}
    local pack = sheetData and sheetData.gamingPack or "Fire & Jade"
    local set  = battleTacticDecks[pack] or {}
    for _, data in pairs(set) do tacticDeckGuids[data.guid] = true end
end

local function _getNotesSafe(o)
    if not o or not o.getGMNotes then return "" end
    local ok, notes = pcall(function() return o.getGMNotes() end)
    return ok and notes or ""
end

local function _setNotesSafe(o, s)
    if not o or not o.setGMNotes then return end
    pcall(function() o.setGMNotes(s) end)
end

local function _isTacticContainer(o)
    if not o then return false end
    if tacticDeckGuids[o.getGUID()] then return true end
    return _getNotesSafe(o) == TACTIC_TAG
end

function onObjectLeaveContainer(container, obj)
    if not container or not obj then return end
    if not _isTacticContainer(container) then return end

    Wait.time(function()
        if not obj or not obj.getGUID then return end
        local tag = obj.tag
        if tag == "Deck" or tag == "DeckCustom" then
            if obj.setGMNotes then obj.setGMNotes(TACTIC_TAG) end
            obj.use_gravity  = true
            obj.interactable = true
        elseif tag == "Card" or tag == "CardCustom" then
            obj.use_gravity  = true
            obj.interactable = true
        end
    end, 0.05)
end


----------------------
-- HELPER FUNCTIONS --
----------------------

local function _getObj(guid) return guid and getObjectFromGUID(guid) or nil end

local function _terrainGuidsForPack(pack)
    local res, set = {}, terrainObjects[pack]
    if not set then return res end
    for _, item in ipairs(set) do table.insert(res, item.guid) end
    return res
end

local function _captureTerrainTransforms(guidList)
    local t = {}
    for _, guid in ipairs(guidList) do
        local obj = _getObj(guid)
        if obj then
            t[guid] = {
                pos     = obj.getPosition(),
                rot     = obj.getRotation(),
                locked  = obj.getLock(),
                gravity = obj.use_gravity == true
            }
        end
    end
    return t
end

local function _applyTerrainTransforms(saved)
    if not saved or not saved.transforms then return end
    for guid, tf in pairs(saved.transforms) do
        local obj = _getObj(guid)
        if obj and tf.pos and tf.rot then
            obj.setPosition(tf.pos)
            obj.setRotation(tf.rot)
            if tf.locked ~= nil then obj.setLock(tf.locked) end
            if tf.gravity ~= nil then obj.use_gravity = tf.gravity end
        end
    end
end




function onLoad(saved_state)
    local savedData = nil

    if saved_state and saved_state ~= "" then
        local ok, data = pcall(JSON.decode, saved_state)
        if ok and type(data) == "table" then
            restoringFromSave = true        -- <-- we're restoring a save
            savedData    = data
            buttonStates = data.buttonStates or {}
            sheetData    = data.sheetData or sheetData
        else
            buttonStates = buttonStates or {}
            sheetData    = sheetData or {}
        end
    else
        buttonStates = buttonStates or {}
        sheetData    = sheetData or {}
    end

    local staticXml = [[
        <Panel>
            <!-- PLAYER NAME DISPLAY -->
            <Text id="playerName1" fontSize="50" fontStyle="Bold" alignment="MiddleCenter"
                  position="840 450 -15" width="500" height="60" rotation="0 0 270"
                  text="Player 1" color="#FF4444FF" />

            <Text id="playerName2" fontSize="50" fontStyle="Bold" alignment="MiddleCenter"
                  position="840 -450 -15" width="500" height="60" rotation="0 0 270"
                  text="Player 2" color="#4488FFFF" />

            <!-- PLAYER 1 - Teammate -->
            <Text id="playerName1b" fontSize="44" fontStyle="Bold" alignment="MiddleCenter"
                  position="745 450 -15" width="520" height="90" rotation="0 0 270"
                  text="Waiting for Pink" color="#FF88CCFF" />

            <!-- PLAYER 2 - Teammate -->
            <Text id="playerName2b" fontSize="44" fontStyle="Bold" alignment="MiddleCenter"
                  position="745 -450 -15" width="520" height="90" rotation="0 0 270"
                  text="Waiting for Teal" color="#44FFFFFF" />

            <!-- GAMING PACK SELECTOR -->
            <Button id="gamingPack" onClick="cycleGamingPack" text="Fire &amp; Jade" fontSize="24" fontStyle="Bold"
                    position="740 100 -20" width="200" height="45" rotation="0 0 270"
                    colors="#5d5d5dff|#6e6e6eff|#8c8c8c"
                    textColor="#FFFFFFFF" />

            <!-- REALM SELECTOR -->
            <Button id="realmSelect" onClick="cycleRealm" text="Aqshy" fontSize="24" fontStyle="Bold"
                    position="740 -100 -20" width="200" height="45" rotation="0 0 270"
                    colors="#5d5d5dff|#6e6e6eff|#8c8c8c"
                    textColor="#FFFFFFFF" />

            <!-- PLAYER 1 - Total Score -->
            <Text id="scoreValue1" fontSize="200" fontStyle="Bold" alignment="MiddleCenter"
                  position="-760 450 -15" width="400" height="250" rotation="0 0 270"
                  text="0" color="#FF8888FF" />

            <!-- PLAYER 2 - Total Score -->
            <Text id="scoreValue2" fontSize="200" fontStyle="Bold" alignment="MiddleCenter"
                  position="-760 -450 -15" width="400" height="250" rotation="0 0 270"
                  text="0" color="#88BBFFFF" />
        </Panel>
    ]]

    local dynamicXml = generateControlButtonsXml()
    self.UI.setXml(staticXml .. dynamicXml)

    Wait.time(function()
        updatePlayerNames()
        restoreFromState(savedData)
        _refreshTacticWhitelist()
        Wait.time(function() restoringFromSave = false end, 0.4)
    end, 0.2)
end

function onSave()
    local currentPack = sheetData and sheetData.gamingPack or "Fire & Jade"
    local terrainGuids = _terrainGuidsForPack(currentPack)
    local terrainTransforms = _captureTerrainTransforms(terrainGuids)

    local data = {
        version      = STATE_VERSION,
        buttonStates = buttonStates or {},
        sheetData    = sheetData or {},
        terrain      = {
            pack       = currentPack,
            transforms = terrainTransforms
        }
    }
    return JSON.encode(data)
end

function generateControlButtonsXml()
    local xml = ""

    local fontSize = "24"
    local width = "200"
    local height = "70"
    local rotation = "0 0 270"

    for round = 1, 4 do

        for player = 1, 2 do
            local yOffset = (player == 1) and 625 or -235
            local xOffset = 500 - ((round - 1) * 315)
            local suffix = "_" .. round .. "_" .. player

            -- Objective Control Toggles
            for i, label in ipairs({"Control 2+", "Control 4+", "Control More"}) do
                local id = "control" .. i .. suffix
                local yPos = yOffset - ((i - 1) * 200)

                xml = xml .. string.format([[
                    <ToggleButton id="%s" onValueChanged="toggleControlButton" text="%s" fontSize="%s"
                        position="%d %d -15" width="%s" height="%s" rotation="%s"
                        deselectedBackgroundColor="#5d5d5dff" selectedBackgroundColor="#66BBFFFF"
                        textColor="#FFFFFFFF" />
                ]], id, label, fontSize, xOffset, yPos, width, height, rotation)
            end

            -- Battle Tactic Toggles
            for i = 1, 3 do
                local id = "btactic" .. i .. suffix
                local xPos = xOffset - 58
                local yPos = (player == 1) and (yOffset - 125 - ((i - 1) * 70)) or (yOffset - 280 + ((i - 1) * 70))

                xml = xml .. string.format([[
                    <Toggle id="%s" onValueChanged="toggleControlButton"
                        position="%d %d -15" width="50" height="50" rotation="%s"
                        textColor="#FFFFFFFF" />
                ]], id, xPos, yPos, rotation)
            end

            -- Twist Bonus Controls
            local twistYBase = (player == 1) and (yOffset - 180) or (yOffset - 225)
            local twistSpacing = 45

            -- Define your per-round, per-player nudge values here:
            -- These can be replaced with functions or data structures if you want more control
            local twistOffsetX = -105  -- nudges the whole cluster left/right
            local twistOffsetY = 0    -- nudges this cluster up/down (per player-round)

            local twistTextId = "twistText" .. suffix

            -- Final calculated position for this twist cluster
            local twistX = xOffset + twistOffsetX
            local twistY = twistYBase + twistOffsetY

            xml = xml .. string.format([[
                <Button id="dec%s" onClick="adjustTwistBonus" text="-" fontSize="30"
                        position="%d %d -15" width="50" height="50" rotation="%s"
                        colors="#444444FF|#555555FF|#666666FF" textColor="#FFFFFFFF" />
                <Text id="%s" text="0" fontSize="30" alignment="MiddleCenter"
                      position="%d %d -15" width="60" height="50" rotation="%s"
                      color="#FFFFFFFF" />
                <Button id="inc%s" onClick="adjustTwistBonus" text="+" fontSize="30"
                        position="%d %d -15" width="50" height="50" rotation="%s"
                        colors="#444444FF|#555555FF|#666666FF" textColor="#FFFFFFFF" />
            ]],
            suffix, twistX, twistY + twistSpacing, rotation,
            twistTextId, twistX, twistY, rotation,
            suffix, twistX, twistY - twistSpacing, rotation)

        end
    end

    return xml
end

function adjustTwistBonus(_, _, id)
    local isIncrement = id:find("inc") ~= nil
    local suffix = id:match("_(%d+_%d+)$")  -- captures round_player, e.g., "3_2"
    if not suffix then return end

    local key = "twistBonus_" .. suffix
    local textId = "twistText_" .. suffix

    sheetData[key] = sheetData[key] or 0
    if isIncrement then
        sheetData[key] = sheetData[key] + 1
    else
        sheetData[key] = math.max(0, sheetData[key] - 1)
    end

    self.UI.setAttribute(textId, "text", tostring(sheetData[key]))
    updatePlayerScore()
end


function toggleControlButton(_, _, id)
    if buttonStates[id] == nil then buttonStates[id] = false end
    buttonStates[id] = not buttonStates[id]
    local isOn = buttonStates[id]
    self.UI.setAttributes(id, {
        isOn      = isOn and "true" or "false",
        fontStyle = isOn and "Bold" or "Normal",
        textColor = "#FFFFFFFF"
    })
    updatePlayerScore()
end


function updatePlayerScore()
    local score1, score2 = 0, 0

    for id, state in pairs(buttonStates) do
        if state then
            if id:match("_1$") then score1 = score1 + 1 end
            if id:match("_2$") then score2 = score2 + 1 end
        end
    end

    for k, v in pairs(sheetData) do
        if k:match("^twistBonus_%d+_1$") then
            score1 = score1 + v
        elseif k:match("^twistBonus_%d+_2$") then
            score2 = score2 + v
        end
    end

    self.UI.setAttribute("scoreValue1", "text", tostring(score1))
    self.UI.setAttribute("scoreValue2", "text", tostring(score2))
end


function onPlayerChangeColor()
    updatePlayerNames()
end

function updatePlayerNames()
    local red = Player["Red"]
    local pink = Player["Pink"]
    local blue = Player["Blue"]
    local teal = Player["Teal"]

    local redName = (red and red.steam_name) or "Waiting for Red"
    local pinkName = (pink and pink.steam_name) or "Waiting for Pink"
    local blueName = (blue and blue.steam_name) or "Waiting for Blue"
    local tealName = (teal and teal.steam_name) or "Waiting for Teal"

    self.UI.setAttribute("playerName1", "text", redName)
    self.UI.setAttribute("playerName1b", "text", pinkName)
    self.UI.setAttribute("playerName2", "text", blueName)
    self.UI.setAttribute("playerName2b", "text", tealName)
end

-- Alliance and Spearhead selection
alliances = { "Order", "Chaos", "Death", "Destruction" }

spearheads = {
    ["Order"] = {
        "Cities of Sigmar\nCastelite Company",
        "Cities of Sigmar\nFusil-Platoon",
        "Daughters of Khaine\nHeartflayer Troupe",
        "Fyreslayers\nSaga Axeband",
        "Idoneth Deepkin\nAkhelian Tide Guard",
        "Idoneth Deepkin\nSoulraid Hunt",
        "Kharadron Overlords\nGrundstok Trailblazers",
        "Kharadron Overlords\nSkyhammer Task Force",
        "Lumineth Realm-lords\nGlittering Phalanx",
        "Lumineth Realm-lords\nHurakan Vanguard",
        "Seraphon\nStarscale Warhost",
        "Seraphon\nSunblooded Prowlers",
        "Stormcast Eternals\nVigilant Brotherhood",
        "Stormcast Eternals\nYndrasta's Spearhead",
        "Sylvaneth\nBitterbark Copse"
    },
    ["Chaos"] = {
        "Blades of Khorne\nBloodbound Gore Pilgrims",
        "Blades of Khorne\nFangs of the Blood God",
        "Disciples of Tzeentch\nFluxblade Coven",
        "Disciples of Tzeentch\nTzaangor Warflock",
        "Hedonites of Slaanesh\nBlades of the Lurid Dream",
        "Helsmiths of Hashut\nHelforge Host",
        "Maggotkin of Nurgle\nBleak Host",
        "Maggotkin of Nurgle\nBubonic Cell",
        "Skaven\nGnawfeast Clawpack",
        "Skaven\nWarpspark Clawpack",
        "Slaves to Darkness\nBloodwind Legion",
        "Slaves to Darkness\nDarkoath Raiders"
    },
    ["Death"] = {
        "Flesh-eater Courts\nCarrion Retainers",
        "Flesh-eater Courts\nCharnel Watch",
        "Nighthaunt\nCursed Shacklehorde",
        "Nighthaunt\nSlasher Host",
        "Ossiarch Bonereapers\nTithe-Reaper Echelon",
        "Ossiarch Bonereapers\nMortisan Elite",
        "Soulblight Gravelords\nBloodcrave Hunt",
        "Soulblight Gravelords\nDeathrattle Tomb Host"
    },
    ["Destruction"] = {
        "Gloomspite Gitz\nBad Moon Madmob",
        "Gloomspite Gitz\nSnarlpack Huntaz",
        "Ogor Mawtribes\nScrapglutt",
        "Ogor Mawtribes\nTyrant's Bellow",
        "Orruk Warclans\nIronjawz Bigmob",
        "Orruk Warclans\nSwampskulka Gang",
        "Sons of Behemat\nWallsmasher Stomp"
    }
}

sheetData = {
    alliance1 = "Grand Alliance",
    spearhead1 = "Spearhead",
    alliance2 = "Grand Alliance",
    spearhead2 = "Spearhead",
    gamingPack = "Fire & Jade",
    realm = "Aqshy",
    totalScore1 = 0,
    totalScore2 = 0
}

spawnedTerrain = {}
spawnedBattleDecks = {}
spawnedDeck = nil

-- GUID of the root board object in the scene (must support setState)
boardGUID = "55d88a"  -- This is the object placed in TTS with multiple states

-- Board configuration: realm → {state index, GUID of that state}
boardStates = {
    Aqshy = { state = 1, guid = "55d88a" },
    Ghyran = { state = 2, guid = "5f849b" },
    Ossia = { state = 3, guid = "13dee0" },
    Dolorum = { state = 4, guid = "53777e" }
}

board2States = {
    Aqshy = { state = 1, guid = "850fc6" },
    Ghyran = { state = 2, guid = "bf54d5" },
    Ossia = { state = 3, guid = "32d448" },
    Dolorum = { state = 4, guid = "6f30ce" }
}


terrainObjects = {
    ["Fire & Jade"] = {
        -- 2v2: only the original terrain set is spawned. Center = {-33.05, 0.81, 0.44}.
        { guid = "d8daa9", position = {x = -34.30, y = 0.81, z = -3.560001}, rotation = {x = 0, y = 225, z = 0} },
        { guid = "ae161b", position = {x = -34.30, y = 0.81, z = 4.440003}, rotation = {x = 0, y = 315, z = 0} },
        { guid = "af3b95", position = {x = -31.80, y = 0.81, z = -1.560001}, rotation = {x = 0, y = 225, z = 0} },
        { guid = "a6132f", position = {x = -31.80, y = 0.81, z = 2.439999}, rotation = {x = 0, y = 315, z = 0} }
    },
    ["Sand & Bone"] = {
        -- 2v2: preserve original Sand & Bone formation, moved to center {-33.05, 0.44}.
        { guid = "bb1f12", position = {x = -34.05, y = 2.10, z = -4.56}, rotation = {x = 0, y = 315, z = 0} },
        { guid = "e8fb47", position = {x = -32.05, y = 2.40, z = -3.06}, rotation = {x = 0, y = 315, z = 0} },
        { guid = "4e2bf4", position = {x = -34.05, y = 2.15, z = 5.44}, rotation = {x = 0, y = 225, z = 0} },
        { guid = "08fe41", position = {x = -32.05, y = 1.89, z = 3.94}, rotation = {x = 0, y = 225, z = 0} },
        { guid = "3ecf12", position = {x = -31.05, y = 3.29, z = 0.44}, rotation = {x = 0, y = 180, z = 0} },
        { guid = "0ddfd2", position = {x = -35.05, y = 1.40, z = 0.44}, rotation = {x = 0, y = 180, z = 0} }
    }
}

realmDecks = {
    ["Ghyran"] = {
        guid = "ef07e1",
        position = {x = -21.5, y = 0.87, z = -5.5},
        rotation = {x = 0.00, y = 90.00, z = 180.00}
    },
    ["Aqshy"] = {
        guid = "3e637a",
        position = {x = -21.5, y = 0.87, z = -5.5},
        rotation = {x = 0.00, y = 90.00, z = 180.00}
    },
    ["Ossia"] = {
        guid = "61b20e",
        position = {x = -21.5, y = 0.87, z = -5.5},
        rotation = {x = 0.00, y = 90.00, z = 180.00}
    },
    ["Dolorum"] = {
        guid = "4554fe",
        position = {x = -21.5, y = 0.87, z = -5.5},
        rotation = {x = 0.00, y = 90.00, z = 180.00}
    }
}

territoryOverlays = {
    ["Fire & Jade"] = {
        { state = 1, guid = "a5109b", position = {x = 31.50, y = 0.89, z = 12.00}, rotation = {x = 0, y = 0, z = 180} },
        { state = 2, guid = "a5d951", position = {x = 19.50, y = 0.89, z = 12.00}, rotation = {x = 0, y = 0, z = 180} },
        { state = 3, guid = "cefcd9", position = {x = 19.50, y = 0.89, z = 12.00}, rotation = {x = 0, y = 0, z = 180} }
    },
    ["Sand & Bone"] = {
        { state = 1, guid = "9b180a", position = {x = 31.50, y = 0.89, z = 12.00}, rotation = {x = 0, y = 0, z = 180} },
        { state = 2, guid = "765d58", position = {x = 19.50, y = 0.89, z = 12.00}, rotation = {x = 0, y = 0, z = 180} },
        { state = 3, guid = "0d990f", position = {x = 19.50, y = 0.89, z = 12.00}, rotation = {x = 0, y = 0, z = 180} }
    }
}

terrainOverlays = {
    ["Fire & Jade"] = {
        { state = 1, guid = "9fe02b", position = {x = 31.50, y = 0.89, z = 8.00}, rotation = {x = 0, y = 0, z = 180} },
        { state = 2, guid = "ebd1b3", position = {x = 19.50, y = 0.89, z = 8.00}, rotation = {x = 0, y = 0, z = 180} },
        { state = 3, guid = "595a07", position = {x = 19.50, y = 0.89, z = 8.00}, rotation = {x = 0, y = 0, z = 180} }
    },
    ["Sand & Bone"] = {
        { state = 1, guid = "4a1317", position = {x = 31.50, y = 0.89, z = 8.00}, rotation = {x = 0, y = 0, z = 180} },
        { state = 2, guid = "24bc1f", position = {x = 19.50, y = 0.89, z = 8.00}, rotation = {x = 0, y = 0, z = 180} },
        { state = 3, guid = "ac093c", position = {x = 19.50, y = 0.89, z = 8.00}, rotation = {x = 0, y = 0, z = 180} }
    }
}

deploymentOverlays = {
    ["Fire & Jade"] = {
        { state = 1, guid = "bd190b", position = {x = 31.50, y = 0.89, z = 4.00}, rotation = {x = 0, y = 0, z = 180} },
        { state = 2, guid = "eaa9a7", position = {x = 19.50, y = 0.89, z = 4.00}, rotation = {x = 0, y = 0, z = 180} },
        { state = 3, guid = "7b966f", position = {x = 19.50, y = 0.89, z = 4.00}, rotation = {x = 0, y = 0, z = 180} }
    },
    ["Sand & Bone"] = {
        { state = 1, guid = "a2056b", position = {x = 31.50, y = 0.89, z = 4.00}, rotation = {x = 0, y = 0, z = 180} },
        { state = 2, guid = "bdcfc7", position = {x = 19.50, y = 0.89, z = 4.00}, rotation = {x = 0, y = 0, z = 180} },
        { state = 3, guid = "4aa032", position = {x = 19.50, y = 0.89, z = 4.00}, rotation = {x = 0, y = 0, z = 180} }
    }
}

battleTacticDecks = {
    ["Fire & Jade"] = {
        p1 = {
            guid = "4a1831",
            position = {x = 34.00, y = 0.62, z = -32.00},
            rotation = {x = 0.00, y = 180.00, z = 180.00},
            scale = {x = 2.24, y = 1.0, z = 2.24}
        },
        p2 = {
            guid = "17f287",
            position = {x = -34.00, y = 0.62, z = 32.00},
            rotation = {x = 0.00, y = 0.00, z = 180.00},
            scale = {x = 2.24, y = 1.0, z = 2.24}
        }
    },
    ["Sand & Bone"] = {
        p1 = {
            guid = "f38ad0",
            position = {x = 34.00, y = 0.62, z = -32.00},
            rotation = {x = 0.00, y = 180.00, z = 180.00},
            scale = {x = 2.24, y = 1.0, z = 2.24}
        },
        p2 = {
            guid = "7da1a2",
            position = {x = -34.00, y = 0.62, z = 32.00},
            rotation = {x = 0.00, y = 0.00, z = 180.00},
            scale = {x = 2.24, y = 1.0, z = 2.24}
        }
    }
}


realmTwists = {
    Aqshy = {
        "Ring of Fire",
        "Let the Blood Flow",
        "Bloodmarked",
        "Reclaim Aqshy",
        "Mount the Attack",
        "Wreathed in Smoke"
    },
    Ghyran = {
        "Take the Land",
        "Reclaim Ghyran",
        "Alarielle's Blessing",
        "The Grandfather's Blessing",
        "Lifespring",
        "Grasping Vines"
    },
    Ossia = {
        "Invincible Redoubts",
        "Secured Supply Lines",
        "Will of the Necropolis",
        "Uncompromising Invasion",
        "Disciplined Conquest",
        "Co-ordinated Bombardment"
    },
    Dolorum = {
        "Survivor's Grief",
        "Savage Mourning",
        "Overpowering Grief",
        "Haunted Locus",
        "Darkened Skies",
        "Banish Your Fears"
    }
}


function cycleAlliance(player, _, id)
    local slot = id == "alliance1" and "1" or "2"
    local current = sheetData["alliance" .. slot]

    if current == "Grand Alliance" or not current then
        local firstAlliance = alliances[1]
        sheetData["alliance" .. slot] = firstAlliance
        sheetData["spearhead" .. slot] = spearheads[firstAlliance][1]
        self.UI.setAttributes("alliance" .. slot, {
            text = firstAlliance,
            textColor = "#FFFFFFFF"
        })
        self.UI.setAttributes("spearhead" .. slot, {
            text = spearheads[firstAlliance][1],
            textColor = "#FFFFFFFF"
        })
        return
    end

    local index = indexOf(alliances, current) or 0
    local nextIndex = (index % #alliances) + 1
    local nextAlliance = alliances[nextIndex]

    sheetData["alliance" .. slot] = nextAlliance
    sheetData["spearhead" .. slot] = spearheads[nextAlliance][1]

    self.UI.setAttributes("alliance" .. slot, {
        text = nextAlliance,
        textColor = "#FFFFFFFF"
    })
    self.UI.setAttributes("spearhead" .. slot, {
        text = spearheads[nextAlliance][1],
        textColor = "#FFFFFFFF"
    })

end

function cycleSpearhead(player, _, id)
    local slot = id == "spearhead1" and "1" or "2"
    local currentAlliance = sheetData["alliance" .. slot]
    local currentSpearhead = sheetData["spearhead" .. slot]

    local list = spearheads[currentAlliance] or {"Spearhead"}
    local index = indexOf(list, currentSpearhead) or 0
    local nextIndex = (index % #list) + 1
    local nextSpearhead = list[nextIndex]

    sheetData["spearhead" .. slot] = nextSpearhead
    self.UI.setAttributes("spearhead" .. slot, {
        text = nextSpearhead,
        textColor = "#FFFFFFFF"
    })
end

function cycleGamingPack(_, _, _)
    local packs = {"Fire & Jade", "Sand & Bone"}
    local current = sheetData["gamingPack"]
    local index = indexOf(packs, current) or 1
    local nextIndex = (index % #packs) + 1
    local next = packs[nextIndex]

    sheetData["gamingPack"] = next
    self.UI.setAttributes("gamingPack", {
        text = next,
        textColor = "#FFFFFFFF"
    })

    -- Despawn all objects tied to the previous pack
    despawnTerrain(current)
    despawnBattleTactics(current)

    -- Spawn new terrain and battle tactic decks
    if terrainObjects[next] then spawnTerrain(next) end
    spawnBattleTactics(next)

    -- Determine realm based on new pack
    local realm = (next == "Fire & Jade") and "Aqshy" or "Ossia"
    sheetData["realm"] = realm
    self.UI.setAttributes("realmSelect", {
        text = realm,
        textColor = "#FFFFFFFF"
    })

    -- Clear removed Twist selector state
    for i = 1, 4 do
        sheetData["twistCycle_" .. i] = nil
    end

    -- Update board, twist deck, and zone overlays
    switchBoard(realm)
    swapDeck(realm)
    despawnZoneTokens(current)
    spawnZoneTokens(next)
end


function cycleRealm(_, _, _)
    local currentPack = sheetData["gamingPack"]
    local realms = (currentPack == "Fire & Jade") and {"Aqshy", "Ghyran"} or {"Ossia", "Dolorum"}

    local current = sheetData["realm"]
    local index = indexOf(realms, current) or 1
    local nextIndex = (index % #realms) + 1
    local next = realms[nextIndex]
    sheetData["realm"] = next

    self.UI.setAttributes("realmSelect", {
        text = next,
        textColor = "#FFFFFFFF"
    })

    -- Clear removed Twist selector state
    for i = 1, 4 do
        sheetData["twistCycle_" .. i] = nil
    end

    switchBoard(next)
    swapDeck(next)
end

function cycleTwistCard(_, _, id)
    -- Twist selectors were removed from the 2v2 sheet; keep this callback harmless for old saves.
end

function spawnTerrain(pack)
    local terrainSet = terrainObjects[pack]
    if not terrainSet then
        print("[spawnTerrain] No terrain defined for pack: " .. tostring(pack))
        return
    end

    Wait.time(function()
        spawnedTerrain = {}
        for _, data in ipairs(terrainSet) do
            local obj = getObjectFromGUID(data.guid)
            if obj then
                obj.setPosition(data.position)
                obj.setRotation(data.rotation)
                obj.unlock() -- allow user interaction
                obj.use_gravity = true -- enable gravity so they sit naturally
                obj.interactable = true
                table.insert(spawnedTerrain, obj)
            else
                print("[spawnTerrain] Could not find object with GUID: " .. data.guid)
            end
        end
    end, 0.1)
end


function despawnTerrain(pack)
    -- hacky fix for not despawning on first switch after load
    hideTerrain(pack)

--     for _, obj in ipairs(spawnedTerrain) do
--         if obj then
--             obj.setPosition({x = 0, y = -10, z = 0})
--             obj.lock()
--             obj.use_gravity = false
--         end
--     end
    spawnedTerrain = {}
end


function hideTerrain(pack)
    -- hacky fix for not despawning on first switch after load
    local terrainSet = terrainObjects[pack]
    if not terrainSet then
        print("[spawnTerrain] No terrain defined for pack: " .. tostring(pack))
        return
    end

    Wait.time(function()
        spawnedTerrain = {}
        for _, data in ipairs(terrainSet) do
            local obj = getObjectFromGUID(data.guid)
            if obj then
                obj.setPosition({x = 0, y = -10, z = 0})
                obj.lock()
                obj.interactable = false
                obj.use_gravity = false
            end
        end
    end, 0.1)
end


function switchBoard(realm)
    local cfg1 = boardStates[realm]
    local cfg2 = board2States and board2States[realm] or nil
    if not cfg1 then
        print("[switchBoard] No board state defined for realm: " .. tostring(realm))
        return
    end

    local function applyBoard(stateCfg, allGuids)
        if not stateCfg then return end
        local found
        for _, g in pairs(allGuids) do
            local o = getObjectFromGUID(g)
            if o then found = o; break end
        end
        if not found then return end
        if tonumber(found.getStateId()) == tonumber(stateCfg.state) then return end
        found.setState(stateCfg.state)
    end

    local guids1 = {}
    for _, v in pairs(boardStates) do table.insert(guids1, v.guid) end
    applyBoard(cfg1, guids1)

    if cfg2 then
        local guids2 = {}
        for _, v in pairs(board2States) do table.insert(guids2, v.guid) end
        applyBoard(cfg2, guids2)
    end
end


function swapDeck(realm)
    -- hide previous
    if spawnedDeck then
        spawnedDeck.setPosition({x = 0, y = -10, z = 0})
        spawnedDeck.lock()
        spawnedDeck.use_gravity = false
        spawnedDeck.interactable = false
        spawnedDeck = nil
    end

    Wait.time(function()
        local data = realmDecks[realm]
        if not data then print("[swapDeck] No deck for realm: " .. tostring(realm)); return end

        local obj = _getObj(data.guid)
        if obj then
            obj.setPosition(data.position)
            obj.setRotation(data.rotation)
            obj.unlock()
            obj.use_gravity = true
            obj.interactable = true
            if obj.shuffle and not restoringFromSave then obj.shuffle() end
            spawnedDeck = obj
        else
            print("[swapDeck] Missing deck GUID: " .. tostring(data.guid))
        end

        -- disable other realm decks for safety
        for rName, rData in pairs(realmDecks) do
            if rName ~= realm then
                local other = _getObj(rData.guid)
                if other then other.interactable = false end
            end
        end
    end, 0.1)
end


-- despawns all tokens for given pack
function despawnZoneTokens(pack)
    local territoryTokens = territoryOverlays[pack]
    if not territoryTokens then
        print("[resetTokenStates] No territory overlays defined for pack: " .. tostring(pack))
        return
    end
    despawnToken(territoryTokens)

    local terrainTokens = terrainOverlays[pack]
    if not terrainTokens then
        print("[resetTokenStates] No terrain overlays defined for pack: " .. tostring(pack))
        return
    end
    despawnToken(terrainTokens)

    local deploymentTokens = deploymentOverlays[pack]
    if not deploymentTokens then
        print("[resetTokenStates] No deployment overlays defined for pack: " .. tostring(pack))
        return
    end
    despawnToken(deploymentTokens)
end


-- despawns given token type
function despawnToken(tokenSet)
    Wait.time(function()
        for _, data in ipairs(tokenSet) do
            local obj = getObjectFromGUID(data.guid)
            if obj then
                obj.setPosition({x = 0, y = -10, z = 0})
                obj.lock()
                obj.use_gravity = false
                obj.interactable = false
                -- Overlays 2v2 ya no usan States internos; evitar setState en botones/plantillas.
            end
        end
    end, 0.1)
end


-- spawns all tokens for given pack
function spawnZoneTokens(pack)
    local territoryTokens = territoryOverlays[pack]
    if not territoryTokens then
        print("[resetTokenStates] No territory overlays defined for pack: " .. tostring(pack))
        return
    end
    spawnToken(territoryTokens)

    local terrainTokens = terrainOverlays[pack]
    if not terrainTokens then
        print("[resetTokenStates] No terrain overlays defined for pack: " .. tostring(pack))
        return
    end
    spawnToken(terrainTokens)

    local deploymentTokens = deploymentOverlays[pack]
    if not deploymentTokens then
        print("[resetTokenStates] No deployment overlays defined for pack: " .. tostring(pack))
        return
    end
    spawnToken(deploymentTokens)
end


-- spawns given token type
function spawnToken(tokenSet)
    Wait.time(function()
        for _, data in ipairs(tokenSet) do
            -- En 2v2 solo los state=1 son botones. Los state=2/3 son plantillas ocultas.
            if data.state == nil or data.state == 1 then
                local obj = getObjectFromGUID(data.guid)
                if obj then
                    obj.setPosition(data.position)
                    obj.setRotation(data.rotation)
                    obj.lock()
                    obj.use_gravity = true
                    obj.interactable = true
                    if obj.setInvisibleTo then obj.setInvisibleTo({}) end
                end
            end
        end
    end, 0.1)
end


function spawnBattleTactics(pack)
    local deckSet = battleTacticDecks[pack]
    if not deckSet then
        print("[spawnBattleTactics] No decks for pack: " .. tostring(pack)); return
    end

    Wait.time(function()
        for player, data in pairs(deckSet) do
            local obj = getObjectFromGUID(data.guid)
            if obj then
                obj.setPosition(data.position)
                obj.setRotation(data.rotation)
                if data.scale then obj.setScale(data.scale) end
                obj.unlock()
                obj.use_gravity  = true
                obj.interactable = true
                if obj.setGMNotes then obj.setGMNotes(TACTIC_TAG) end
                if obj.shuffle and not restoringFromSave then obj.shuffle() end
                spawnedBattleDecks[player] = obj

                -- re-assert gravity after engine settles internal moves
                Wait.time(function() if obj then obj.use_gravity = true end end, 0.12)
                Wait.time(function() if obj then obj.use_gravity = true end end, 0.35)
            else
                print("[spawnBattleTactics] Missing deck for " .. tostring(player) .. " (GUID: " .. tostring(data.guid) .. ")")
            end
        end
        _refreshTacticWhitelist()
    end, 0.1)
end


function despawnBattleTactics(pack)
    -- hacky fix for not despawning on first switch after load
    hideBattleTactics(pack)

--     if not next(spawnedBattleDecks) then
--         print("[despawnBattleTactics] Nothing to despawn.")
--         return
--     end
--
--     for key, obj in pairs(spawnedBattleDecks) do
--         if obj and obj.getPosition then
--             obj.setPosition({x = 0, y = -10, z = 0})
--             obj.lock()
--             obj.use_gravity = false
--             obj.interactable = false
--         end
--     end
--
    spawnedBattleDecks = {}
end


function hideBattleTactics(pack)
    -- hacky fix for not despawning on first switch after load
    local deckSet = battleTacticDecks[pack]
    if not deckSet then
        print("[spawnBattleTactics] No decks for pack: " .. tostring(pack)); return
    end

    Wait.time(function()
        for player, data in pairs(deckSet) do
            local obj = getObjectFromGUID(data.guid)
            if obj and obj.getPosition then
                obj.setPosition({x = 0, y = -10, z = 0})
                obj.lock()
                obj.use_gravity = false
                obj.interactable = false
            end
        end
        _refreshTacticWhitelist()
    end, 0.1)
end


function incrementTotalScore(player, value, id)
    local slot = (id == "scoreValue1") and "1" or "2"
    local key = "totalScore" .. slot
    local textId = "scoreValue" .. slot

    sheetData[key] = sheetData[key] or 0

    if value == -2 then  -- right click
        sheetData[key] = math.max(0, sheetData[key] - 1)
    else  -- left click or unknown
        sheetData[key] = sheetData[key] + 1
    end

    self.UI.setAttribute(textId, "text", tostring(sheetData[key]))
end


function updateScores()
    self.UI.setAttribute("scoreValue1", "text", tostring(sheetData.totalScore1 or 0))
    self.UI.setAttribute("scoreValue2", "text", tostring(sheetData.totalScore2 or 0))
end

function indexOf(t, value)
    for i, v in ipairs(t) do
        if v == value then return i end
    end
    return nil
end


function restoreFromState(savedData)
    -- UI text
    updatePlayerNames()

    local pack  = sheetData.gamingPack or "Fire & Jade"
    local realm = sheetData.realm or ((pack == "Fire & Jade") and "Aqshy" or "Ossia")
    self.UI.setAttribute("gamingPack","text",pack)
    self.UI.setAttribute("realmSelect","text",realm)
    -- Twist Points bonus counters
    for round = 1, 4 do
        for player = 1, 2 do
            local bk = "twistBonus_" .. round .. "_" .. player
            if sheetData[bk] then
                self.UI.setAttribute("twistText_" .. round .. "_" .. player, "text", tostring(sheetData[bk]))
            end
        end
    end

    -- toggles (keep your white text look)
    for id, state in pairs(buttonStates) do
        self.UI.setAttributes(id, {
            isOn      = state and "true" or "false",
            textColor = state and "#000000FF" or "#FFFFFFFF",  -- if you prefer your v009 style, keep it
            fontStyle = state and "Bold" or "Normal"
        })
    end
    -- ensure certain labels are always white
    for _, id in ipairs({"playerName1","playerName1b","playerName2","playerName2b","gamingPack","realmSelect"}) do
        self.UI.setAttribute(id, "textColor", "#FFFFFFFF")
    end
    updatePlayerScore()

    -- terrain: apply saved transforms; re-seat missing pieces
    do
        local savedTerrain = savedData and savedData.terrain or nil
        _applyTerrainTransforms(savedTerrain)

        local curPack = pack
        local defs    = terrainObjects[curPack] or {}
        for _, def in ipairs(defs) do
            local obj = _getObj(def.guid)
            if obj then
                local pos = obj.getPosition()
                local offTable = (pos.y == nil) or (pos.y < -5)
                if offTable then
                    obj.setPosition(def.position)
                    obj.setRotation(def.rotation)
                    obj.unlock()
                    obj.use_gravity = true
                end
            end
        end
    end

    -- board + twist deck
    switchBoard(realm)
    swapDeck(realm)

    -- hacky fix for things being interactable being clickable through the board
    local packs = {"Fire & Jade", "Sand & Bone"}
    local index = indexOf(packs, pack) or 1
    local inactiveIndex = (index % #packs) + 1
    local inactive = packs[inactiveIndex]
    hideTerrain(inactive)
    hideBattleTactics(inactive)

    -- ensure tactic decks physics are on
    do
        local set = battleTacticDecks[pack] or {}
        for _, data in pairs(set) do
            local o = _getObj(data.guid)
            if o then
                o.use_gravity  = true
                o.interactable = true
            end
        end
    end
end
