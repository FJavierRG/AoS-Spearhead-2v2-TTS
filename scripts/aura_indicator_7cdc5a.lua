-- Exported from Spearhead_2v2.base.json for review only.
-- TTS object: Aura Indicator
-- GUID: 7cdc5a
-- Source of truth: edit this file, then run `python tools/build.py`

--[[LUAStart
-- AREA INDICATOR
-- vdataversion
show = false
version = "dataversion"

function onLoad()
    drawAreas()
end

function createText(txt, position, color, rotation)
    return {
        label=txt,
        click_function="none",
        function_owner=Global,
        position=position,
        rotation=rotation,
        height=0,
        width=0,
        font_size=300,
        font_color={hex2rgbNorm(color)},
		alignment=2
    }
end


function drawAreas()
    local state = getState()

    if next(state) == nil then
        print("State is empty")
        clearAreas()
        return 0
    end

    local alwaysShow = state.config.always_show
    local vectorLines = {}
    local areaText = {}

    local areas = getAreasFromState(state)

    local pos_y = 0
    if state.config.area_pos_y then
        pos_y = state.config.area_pos_y
    end

    local pos_x = 0
    if state.config.area_pos_x then
        pos_x = state.config.area_pos_x
    end

    local pos_z = 0
    if state.config.area_pos_z then
        pos_z = state.config.area_pos_z
    end

    local base_size_x = getBaseSizeX(state)
    local base_size_y = getBaseSizeY(state)
    local scaleFactor = calculateScale()

    -- Base
    table.insert(vectorLines, createArea(base_size_x, base_size_y, "#FFFFFF", pos_y, pos_x, pos_z, 0.02))
    -- Circles
    for i, v in pairs(areas) do
        local radius_x = base_size_x + (v.size / scaleFactor) - (getAreaThickness()/2)
        local radius_y = base_size_y + (v.size / scaleFactor) - (getAreaThickness()/2)
        if getShowAreaNames() then
            local area_text = v.size .. "''"
            if v.name then
                area_text = v.name .. ' ' .. area_text
            end
            local text_offset = getAreaTextOffset()

            local text_distance_x = radius_x + text_offset
            local text_position = { text_distance_x , pos_y , 0}
            table.insert(areaText, createText(area_text, text_position , v.colour, {0,90,0}))

            local text_distance_y = radius_y + text_offset
            local text_position = { 0, pos_y , text_distance_y }
            table.insert(areaText, createText(area_text, text_position , v.colour, {0,180,0}))

            local text_distance_x = radius_x + text_offset
            local text_position = { -text_distance_x , pos_y , 0}
            table.insert(areaText, createText(area_text, text_position , v.colour, {0,-90,0}))

            local text_distance_y = radius_y + text_offset
            local text_position = { 0, pos_y , -text_distance_y }
            table.insert(areaText, createText(area_text, text_position , v.colour, {0,0,0}))
        end

        local circle = createArea(radius_x, radius_y, v.colour, pos_y,pos_x, pos_z, getAreaThickness())
        table.insert(vectorLines, circle)
    end


    for i, v in pairs(areaText) do
        self.createButton(v)
    end

	self.setVectorLines(vectorLines)
end

function clearAreas()
    self.setVectorLines({})

    local buttons = self.getButtons()
    if buttons ~= nil then
        for i, v in pairs(buttons) do
            if i > 1 then
                self.removeButton(i-1)
            end
        end
    end
end

function getAreaTextOffset()
    local state = getState()
    local scaleFactor = calculateScale()

    if state.config.text_offset then
        return state.config.text_offset / scaleFactor
    else
        return 0.5 / scaleFactor
    end
end

function getBaseSizeX(state)
    local size = 1

    local scaleFactor = calculateScale()

    if state.config.base_size then
        return (( state.config.base_size / 2 ) / 25.4 ) / scaleFactor
    end

    if state.config.base_size_x then
        return (( state.config.base_size_x / 2 ) / 25.4 ) / scaleFactor
    end

    return 1
end

function getBaseSizeY(state)
    local size = 1

    local scaleFactor = calculateScale()

    if state.config.base_size then
        return (( state.config.base_size / 2 ) / 25.4 ) / scaleFactor
    end

    if state.config.base_size_x then
        return (( state.config.base_size_y / 2 ) / 25.4 ) / scaleFactor
    end

    return 1
end

function getAreasFromState(state)
    local areas = {}
    for key,value in pairs(state) do
        if key ~= "config" then
            table.insert(areas, value)
        end
    end
    return areas
end

function getShowAreaNames()
    local state = getState()

    if state.config.show_names then
        return state.config.show_names
    else
        return false
    end
end

function calculateScale()
    local state = getState()

    if state.config.scale_factor then
        return scaleFactor
    else
        local scale = self.getScale()
        return scale.x
    end
end

function getRotationVector()
    local state = getState()

    if state.config.rotation then
        return {0, state.config.rotation, 0}
    end

    return {0, 0, 0}
end

function getAreaThickness()
    local state = getState()
    local scaleFactor = calculateScale()
    local thickness = 0.02
    if state.config.thickness then
        thickness = state.config.thickness
    end

    return thickness / scaleFactor
end

function createArea(a, b, colour, pos_y,pos_x, pos_z, thickness)
    return {
		color             = {hex2rgbNorm(colour)},
		thickness         = thickness,
        rotation          = getRotationVector(),
        points            = getAreaVectorPoints(a, b, 64, pos_y, pos_x, pos_z),
	}
end

function getAreaVectorPoints(a, b, steps, y, x, z)
	local t = {}

	local d,s,c,r = 360/steps, math.sin, math.cos, math.rad
	for i = 0,steps do
		table.insert(t, {
			a * s(r(d*i)) + x,
			y,
			b * c(r(d*i)) + z
		})
	end
	return t
end

-- UTILS

function hex2rgbNorm (hex)
    local hex = hex:gsub("#","")
    if hex:len() == 3 then
      return (tonumber("0x"..hex:sub(1,1))*17)/255,
        (tonumber("0x"..hex:sub(2,2))*17)/255,
        (tonumber("0x"..hex:sub(3,3))*17)/255
    else
      return tonumber("0x"..hex:sub(1,2),16)/255, tonumber("0x"..hex:sub(3,4),16)/255, tonumber("0x"..hex:sub(5,6),16)/255
    end
end

-- STATE
function getState()
    local data = {};
    data['config'] = {};
    data['config']['base_size_x'] = databasesizex
    data['config']['base_size_y'] = databasesizey
    data['config']['always_show'] = false
    data['config']['area_pos_x'] = datatareaposx
    data['config']['area_pos_y'] = datatareaposy
    data['config']['area_pos_z'] = datatareaposz
    data['config']['thickness'] = datathickness
    data['config']['text_offset'] = datatextoffset
    data['config']['show_names'] = datashownames
    data['config']['rotation'] = datarotation
    data['area_ident'] = {};
    data['area_ident']['name'] = 'dataname'
    data['area_ident']['size'] = datasize
    data['area_ident']['colour'] = 'datacolour'

    return data
end
LUAStop--lua]]

version = "2.0.0"
data = {}
color = {}

color['White'] = '#FFFFFF'
color['Silver'] = '#C0C0C0' 
color['Gray'] = '#808080'
color['Black'] = '#000000'
color['Red'] = '#FF0000'
color['Maroon'] = '#800000'
color['Yellow'] = '#FFFF00'
color['Olive'] = '#808000'
color['Lime'] = '#00FF00'
color['Green'] = '#008000' 
color['Aqua'] = '#00FFFF'
color['Teal'] = '#008080'
color['Blue'] = '#0000FF'
color['Navy'] = '#000080'
color['Fuchsia'] = '#FF00FF' 
color['Purple'] = '#800080'

data['base_size_x'] = 32
data['base_size_y'] = 32
data['name'] = 'Area Name'
data['size'] = 12
data['colour'] = 'Red'
data['show_names'] = 'true'
data['thickness'] = 0.05
data['rotation'] = 90
data['text_offset'] = -1
data['area_pos_x'] = 0
data['area_pos_y'] = 0.2
data['area_pos_z'] = 0

function onLoad()
    
end

function updateData(player, value, id)
    data[id] = value
end

function toogleChanged(player, value, id)
    data[id] = value:lower()
end

function optionSelected(player, option, id)
    data[id] = option
 end

function addScripts(object)
  if object.tag == "Generic" or object.tag == "Figure" or object.tag == "Tileset" or object.tag == "rpgFigurine" or object.tag == "Figurine" then
    local script = self.getLuaScript()
    local newScript = script:sub(script:find("LUAStart")+8, script:find("LUAStop")-1)

    newScript = replacetext(newScript, 'dataversion', version, false)
    newScript = replacetext(newScript, 'databasesizex', data['base_size_x'], false)
    newScript = replacetext(newScript, 'databasesizey', data['base_size_y'], false)
    newScript = replacetext(newScript, 'dataname', data['name'], false)
    newScript = replacetext(newScript, 'datasize', data['size'], false)
    newScript = replacetext(newScript, 'datacolour', color[data['colour']], false)
    newScript = replacetext(newScript, 'datashownames', data['show_names'], false)
    newScript = replacetext(newScript, 'datathickness', data['thickness'], false)
    newScript = replacetext(newScript, 'datarotation', data['rotation'], false)
    newScript = replacetext(newScript, 'datatextoffset', data['text_offset'], false)
    newScript = replacetext(newScript, 'datatareaposx', data['area_pos_x'], false)
    newScript = replacetext(newScript, 'datatareaposy', data['area_pos_y'], false)
    newScript = replacetext(newScript, 'datatareaposz', data['area_pos_z'], false)
    object.setLuaScript(newScript)
    object.reload()
    print("Area Indicator v"..version.." scripts attached to " .. object.getName() .. "(".. object.getGUID() ..")")
    print("Data:")
    printData()
  else
    print("Area indicator script couln´t be attached to object " .. object.guid .. " with tag " .. object.tag)
  end
end

function printData()
    print(data['base_size_x'])
    print(data['base_size_y'])
    print(data['name'])
    print(data['size'])
    print(color[data['colour']])
    print(data['show_names'])
    print(data['thickness'])
    print(data['rotation'])
    print(data['text_offset'])
    print(data['area_pos_x'])
    print(data['area_pos_y'])
    print(data['area_pos_z'])
end

function selectObjects()
    local BoundsNormalized = self.getBounds()

    local leftBound = BoundsNormalized.center.x-(BoundsNormalized.size.x/2)
    local rightBound = BoundsNormalized.center.x+(BoundsNormalized.size.x/2)
    local upperBound = BoundsNormalized.center.z+(BoundsNormalized.size.z/2)
    local lowerBound = BoundsNormalized.center.z-(BoundsNormalized.size.z/2)
    local yupperBound = BoundsNormalized.center.y+(BoundsNormalized.size.y/2)+3
    local ylowerBound =  BoundsNormalized.center.y-(BoundsNormalized.size.y/2)

    -- Iterate all objects in the zone
    for _, obj in pairs(getAllObjects()) do
        -- Fetch resting objects
        if obj != nil and obj.resting then
            -- Only use objects inside the zone
            local objPos = obj.getPosition()
            if obj.getGUID() ~= self.getGUID() and objPos['x'] > leftBound and objPos['x'] < rightBound and objPos['z'] > lowerBound and objPos['z'] < upperBound and objPos['y'] < yupperBound and objPos['y'] > ylowerBound then
                addScripts(obj)
            end
        end
    end
end

function replacetext(source, find, replace, wholeword)
    if wholeword then
        find = '%f[%a]'..find..'%f[%A]'
    end
    return (source:gsub(find,replace))
end