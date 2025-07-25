local Constants = require("constants")
local BitDecoder = require("utils.bitdecoder")
local TableCopy = require("utils.tablecopy")
local XML = require("utils.xml")

local QUARTER_TURN = math.rad(90)

local module = {}

---@param mapRootNode XmlNode
---@return Map
local function createEmptyMap(mapRootNode)
    local width = tonumber(mapRootNode.attributes.width)
    assert(width and width > 0 and math.floor(width) == width, "map width must be a positive integer")
    local height = tonumber(mapRootNode.attributes.height)
    assert(height and height > 0 and math.floor(height) == height, "map height must be a positive integer")

    ---@type Map
    local map = {
        width = width,
        height = height,
        tilesets = {},
        tileIDMapping = {},
        layers = {},
        walkable = {},
        objects = {},
        namedObjects = {},
    }

    -- populate first dimension of the 2D table for each layer
    local layerColumn
    for _, layer in pairs(TileLayer) do
        layerColumn = {}

        for y = 0, height do
            layerColumn[y] = {}
        end

        map.layers[layer] = layerColumn
    end

    -- populate first dimension of the 2D table for objects table,
    -- and populate both dimensions of the 2D table for walkable tile checks
    for y = 0, height do
        local rows = {}

        for x = 0, width do
            -- all tiles are considered walkable until the scenery layer tile is found
            rows[x] = true
        end

        map.walkable[y] = rows
        map.objects[y] = {}
    end

    return map
end

---@param propertiesNode XmlNode
---@return table<string, any>
local function parseObjectProperties(propertiesNode)
    local properties = {}

    for _, propertyNode in XML.iterNodeChildren(propertiesNode, "property") do
        local propertyType = propertyNode.attributes.type
        local propertyName = propertyNode.attributes.name
        ---@type any
        local propertyValue = propertyNode.attributes.value

        assert(propertyName and propertyValue, "object property name and/or value attributes are missing")

        if propertyType then
            if propertyType == "bool" then
                propertyValue = (propertyValue == "true")
            elseif propertyType == "float" then
                propertyValue = tonumber(propertyValue) or 0.0
            elseif propertyType == "int" then
                propertyValue = math.floor(tonumber(propertyValue) or 0)
            else
                error("object property type \"" .. propertyType .. "\" is unsupported")
            end
        end
        properties[propertyName] = propertyValue
    end

    return properties
end

---@param filepath string
---@param firstGlobalID integer
---@return Tileset
local function loadTilesetFile(filepath, firstGlobalID)
    print("loading tileset \"" .. filepath .. "\"")

    -- strip characters before "assets", as the filepath will be relative to the file main.lua
    local i = string.find(filepath, "assets")
    assert(i, "tileset source \"" .. filepath .. "\" attribute is invalid")
    if i > 1 then filepath = string.sub(filepath, i) end

    local rootNode = XML.loadFromFile(filepath)
    assert(rootNode, "tileset info \"" .. filepath .. "\" not found")

    local tilesetName = rootNode.attributes.name
    assert(tilesetName and string.len(tilesetName) > 0, "tileset \"" .. filepath .. "\" is missing name attribute")

    local tileCount = tonumber(rootNode.attributes.tilecount)
    assert(tileCount and tileCount > 0 and math.floor(tileCount) == tileCount,
        "tileset \"" .. tilesetName .. "\" tileCount attribute is not a positive integer")

    local imageNode = XML.findNodeChild(rootNode, "image")
    assert(imageNode, "tileset \"" .. tilesetName .. "\" does not contain a reference to an image file")

    local imageFilepath = "assets/tilesets/" .. imageNode.attributes.source
    assert(love.filesystem.getInfo(imageFilepath, "file"),
        "tileset \"" .. tilesetName .. "\" image file \"" .. filepath .. "\" not found")

    ---@type Tileset
    local tileset = {
        name = tilesetName,
        tileCount = tileCount,
        firstgid = firstGlobalID,
        source = imageFilepath,
        objectTypes = {},
        defaultObjectProperties = {}
    }

    for _, tileNode in XML.iterNodeChildren(rootNode, "tile") do
        local tileID = tonumber(tileNode.attributes.id)
        assert(tileID and tileID >= 0 and math.floor(tileID) == tileID,
            "id attribute is missing or not a positive integer")

        -- local globalTileID = firstGlobalID + tileID + 1
        local globalTileID = tileID + 1

        local objectTypeName = string.upper(tileNode.attributes.type or "")
        if string.len(objectTypeName) > 0 then
            local objectType = ObjectType[objectTypeName]
            assert(objectType)

            tileset.objectTypes[globalTileID] = objectType
        end

        local propertiesNode = XML.findNodeChild(tileNode, "properties")
        if propertiesNode then
            tileset.defaultObjectProperties[globalTileID] = parseObjectProperties(propertiesNode)
        end
    end

    return tileset
end

---@param mapRootNode XmlNode
---@param map Map
local function parseTilesets(mapRootNode, map)
    ---@type table<string, Tileset> -- maps tileset name to Tileset object
    local tilesetMap = {}
    ---@type table<integer, Tileset> -- maps globalTileID to Tileset object
    local tileIDMapping = {}

    local firstGlobalID, tilesetFilepath, tileset
    for _, tilesetNode in XML.iterNodeChildren(mapRootNode, "tileset") do
        firstGlobalID = tonumber(tilesetNode.attributes.firstgid)
        assert(firstGlobalID, "firstgid attribute missing in tileset")

        tilesetFilepath = tilesetNode.attributes.source
        assert(tilesetFilepath, "source attribute missing in tilesets")

        tileset = loadTilesetFile(tilesetFilepath, firstGlobalID)
        tilesetMap[tileset.name] = tileset

        for id = tileset.firstgid, tileset.firstgid + tileset.tileCount do
            tileIDMapping[id] = tileset
        end
    end

    map.tilesets = tilesetMap
    map.tileIDMapping = tileIDMapping
end

---@param globalTileID integer -- includes flip flags
---@param tileIDMap table<integer, Tileset>
---@return TileInfo
local function parseTileID(globalTileID, tileIDMap)
    local dFlip, vFlip, hFlip

    -- split into actual globalTileID and flip flags
    globalTileID, dFlip, vFlip, hFlip = BitDecoder.decodeTileID(globalTileID)

    -- find which tileset is tied to the globalTileID
    local tileset = tileIDMap[globalTileID]
    assert(tileset)

    -- calculate tileID within the tileset
    local tileID = globalTileID - tileset.firstgid + 1

    -- base tile info
    local tile = {
        tileset = tileset,
        id = tileID
    }

    -- rotation/flipping
    if not dFlip and not hFlip and not vFlip then
        -- no flips
    elseif dFlip and not hFlip and not vFlip then
        -- d
        tile.r = QUARTER_TURN
        tile.sy = -1
    elseif dFlip and hFlip and vFlip then
        -- d + h + v
        tile.r = QUARTER_TURN
        tile.sx = -1
    elseif dFlip and hFlip then
        -- d + h
        tile.r = QUARTER_TURN
    elseif dFlip and vFlip then
        -- d + v
        tile.r = -1 * QUARTER_TURN
    elseif hFlip and vFlip then
        -- h + v
        tile.r = -2 * QUARTER_TURN
    elseif hFlip then
        -- h
        tile.sx = -1
    else
        -- v
        tile.sy = -1
    end

    return tile
end

---@param mapRootNode XmlNode
---@param map Map
local function parseLayers(mapRootNode, map)
    for layerIndex, layerNode in XML.iterNodeChildren(mapRootNode, "layer") do
        local layerName = string.upper(layerNode.attributes.name or "")
        assert(string.len(layerName) > 0, "layer #" .. tostring(layerIndex) .. " has empty name attribute")

        local layerID = TileLayer[layerName]
        assert(layerID, "layer #" .. tostring(layerIndex) .. " \"" .. layerName .. "\" is not one of the expected layers")

        print("loading layer \"" .. layerName .. "\"")

        local layer = map.layers[layerID]

        local tileIndex = 0
        local x, y
        local globalTileID
        for value in string.gmatch(XML.findNodeChild(layerNode, "data").text, "%d+") do
            globalTileID = tonumber(value) or 0

            if globalTileID ~= 0 then
                y, x = math.modf(tileIndex / map.width)
                x = x * map.width

                layer[y][x] = parseTileID(globalTileID, map.tileIDMapping)

                -- collision check for SCENERY layer
                if layerID == TileLayer.SCENERY then
                    -- all scenery layer tiles are impassable
                    map.walkable[y][x] = nil -- nil is used instead of false for memory optimization
                end
            end
            tileIndex = tileIndex + 1
        end
    end
end

---@param mapRootNode XmlNode
---@param map Map
---@param tileSize integer
---@return Player?
local function parseObjects(mapRootNode, map, tileSize)
    ---@type Player?
    local player

    local objectgroupNode = XML.findNodeChild(mapRootNode, "objectgroup")
    assert(objectgroupNode and objectgroupNode.attributes.name == "objects", "objects layer missing")

    for objectIndex, objectNode in XML.iterNodeChildren(objectgroupNode, "object") do
        local objectID = tonumber(objectNode.attributes.id)
        assert(objectID and objectID >= 0 and math.floor(objectID) == objectID,
            "object #" .. tostring(objectIndex) .. " has missing or invalid id attribute")

        local globalTileID = tonumber(objectNode.attributes.gid)
        assert(globalTileID and globalTileID >= 0 and math.floor(globalTileID) == globalTileID,
            "object " .. tostring(objectID) .. " has missing or invalid gid attribute")

        local x = tonumber(objectNode.attributes.x)
        local y = tonumber(objectNode.attributes.y)
        assert(x and y and x >= 0 and y >= 0 and math.floor(x) == x and math.floor(y) == y,
            "object " .. tostring(objectID) .. " has invalid x and/or y attributes")

        -- calculate tile coords from pixels
        x = math.floor(x / tileSize)
        y = math.floor(y / tileSize)

        -- parse the object tile
        local objectTile = parseTileID(globalTileID, map.tileIDMapping)

        ---@type string?
        local objectUniqueName = objectNode.attributes.name
        if objectUniqueName and string.len(objectUniqueName) == 0 then
            -- treat empty string as nil
            objectUniqueName = nil
        end

        ---@type string?
        local objectTypeName = string.upper(objectNode.attributes.type or "")
        local objectType
        if objectTypeName and string.len(objectTypeName) == 0 then
            -- treat empty string as nil
            objectTypeName = nil
        end

        if objectTypeName then
            objectType = ObjectType[objectTypeName]
            assert(objectType, "object " .. tostring(objectID) .. " is not one of the valid object types")
        else
            objectType = objectTile.tileset.objectTypes[objectTile.id]
            assert(objectType, "object " .. tostring(objectID) .. " does not have a type in its related tileset")
        end

        local objectProperties = {}
        if objectUniqueName then
            assert(map.namedObjects[objectUniqueName] == nil,
                "object with uniqueName \"" .. objectUniqueName .. "\" already exists")
        end

        local defaultProperties = objectTile.tileset.defaultObjectProperties[objectTile.id]
        if defaultProperties then
            objectProperties = table.shallowCopy(defaultProperties)
        end

        local propertiesNode = XML.findNodeChild(objectNode, "properties")
        if propertiesNode then
            for propertyName, propertyValue in pairs(parseObjectProperties(propertiesNode)) do
                objectProperties[propertyName] = propertyValue
            end
        end

        ---@type Object
        local object = {
            id = objectID,
            name = objectUniqueName,
            type = objectType,
            x = x,
            y = y,
            tile = objectTile,
            properties = objectProperties,
        }

        if objectType == ObjectType.PLAYER then
            assert(player == nil, "duplicate player object found")
            player = object --[[@as Player]]
        else
            map.objects[y][x] = object
            if objectUniqueName then
                map.namedObjects[objectUniqueName] = object
            end
        end
    end

    return player
end

---@param mapName string
---@return Map?, Player?
function module.loadMapFromFile(mapName)
    local filepath = "maps/" .. mapName .. ".tmx"

    print("loading map \"" .. filepath .. "\"")

    local mapRootNode = XML.loadFromFile(filepath)
    assert(mapRootNode)

    local tileWidth = tonumber(mapRootNode.attributes.tilewidth)
    assert(tileWidth and tileWidth > 0 and math.floor(tileWidth) == tileWidth,
        "map tilewidth must be a positive integer")
    local tileHeight = tonumber(mapRootNode.attributes.tileheight)
    assert(tileHeight and tileHeight > 0 and math.floor(tileHeight) == tileHeight,
        "map tilewidth must be a positive integer")
    assert(tileWidth == tileHeight, "map tilewidth and tileheight must be equal")

    local map = createEmptyMap(mapRootNode)

    print("loading map tilesets")
    parseTilesets(mapRootNode, map)

    print("loading map layer data")
    parseLayers(mapRootNode, map)

    print("loading map objects")
    local player = parseObjects(mapRootNode, map, tileWidth)

    return map, player
end

return module
