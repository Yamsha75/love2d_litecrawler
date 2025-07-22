local XML = require("utils.xml")
-- local TileIDs = require("tileids")

local H_FLIP_MASK = 0x80000000
local V_FLIP_MASK = 0x40000000
local D_FLIP_MASK = 0x20000000
local NOFLIP_MASK = 0x0FFFFFFF

local QUARTER_TURN = math.rad(90)

---@class Tileset
---@field name string
---@field firstgid integer
---@field tileCount integer
---@field source string

---@class Map
---@field width integer
---@field height integer
---@field tilesets table<string, Tileset>
---@field tiles table<TileLayer, Table2D<TileInfo>> -- info for tile rendering only; includes render order
---@field walkable Table2D<boolean> -- info for movement only
---@field interactible Table2D<Entity> -- info for checking interactions
---@field entities table<string, Entity> -- info for turn processing

---@alias Table2D<T> table<integer, table<integer, T>> -- 2D table for mapping coordinates to type T

---@enum TileLayer
local TileLayer = { -- map file layers; also rendering order
    GROUND = 1,     -- no special purpose
    SCENERY = 2,    -- tiles which block movement; can still be interactible
    DECOR = 3,      -- no special purpose
    ENTITIES = 4,   -- all interactibles, including the Player, NPCs, doors, etc.
    FOREGROUND = 5  -- no special purpose
}

---@class TileInfo -- info for tile rendering only
---@field tileset Tileset
---@field id integer tileID within the tileset
---@field x integer positionX
---@field y integer positionY
---@field r number rotation
---@field sx integer scaleX
---@field sy integer scaleY

---@enum EntityType
local EntityType = {
    PLAYER = 1,
    NPC = 2,
    BREAKABLE = 3,
    CONTAINER = 4,
    TRAPDOOR = 5,
    PORTAL = 6,
    ITEM = 7,
    SIGN = 8,
}

---@class Entity : TileInfo -- info about interactible tiles
---@field type EntityType
---@field name string
---@field properties table

local module = { TileLayer = TileLayer, EntityType = EntityType }

---@param source string
---@param firstgid integer
---@return Tileset
local function loadTilesetInfo(source, firstgid)
    local i = string.find(source, "assets")
    assert(i, "source \"" .. source .. "\" value is invalid")

    -- strip characters before "assets", as the filepath will be relative to the file main.lua
    if i > 1 then source = string.sub(source, i) end

    assert(love.filesystem.getInfo(source, "file"), "tileset info \"" .. source .. "\" not found")

    local fileContent = love.filesystem.read(source)
    local rootNode = XML.loadFromString(fileContent)

    local name = rootNode.attributes.name
    assert(name and string.len(name) > 0)

    local tileCount = tonumber(rootNode.attributes.tilecount)
    assert(tileCount)

    local imageNode = XML.findNodeChild(rootNode, "image")
    assert(imageNode)

    local imageFilepath = "assets/gfx/" .. imageNode.attributes.source
    assert(love.filesystem.getInfo(imageFilepath, "file"), "tileset image \"" .. source .. "\" not found")

    ---@type Tileset
    local tileset = {
        name = name,
        tileCount = tileCount,
        firstgid = firstgid,
        source = imageFilepath
    }

    return tileset
end

---@param filename string
---@return Map? map
function module.loadMapFromFile(filename)
    local filepath = "maps/" .. filename .. ".tmx"

    print("trying to load map \"" .. filepath .. "\"")

    if not love.filesystem.getInfo(filepath, "file") then return end

    local fileContent = love.filesystem.read(filepath)
    local rootNode = XML.loadFromString(fileContent)
    assert(rootNode)

    local tileWidth = tonumber(rootNode.attributes.tilewidth)
    local tileHeight = tonumber(rootNode.attributes.tileheight)

    assert(tileWidth and tileHeight)
    assert(tileWidth == tileHeight)

    local width = tonumber(rootNode.attributes.width)
    local height = tonumber(rootNode.attributes.height)
    assert(width and height)

    ---@type Map
    local map = {
        width = width,
        height = height,
        tilesets = {},
        tiles = {},
        walkable = {},
        interactible = {},
        entities = {},
    }

    for _, layerID in pairs(TileLayer) do
        local layer = {}

        for y = 0, height do
            layer[y] = {}
        end

        map.tiles[layerID] = layer
    end

    for y = 0, height do
        local walkable = {}

        for x = 0, width do
            walkable[x] = true
        end

        map.walkable[y] = walkable
        map.interactible[y] = {}
    end

    ---@type table<integer, Tileset>
    local tilesetMapping = {}

    print("loading map tilesets")
    for tilesetNode in XML.iterNodeChildren(rootNode, "tileset") do
        local firstgid = tonumber(tilesetNode.attributes.firstgid)
        assert(firstgid, "firstgid attribute missing in tileset")

        local source = tilesetNode.attributes.source
        assert(source, "source attribute missing in tilesets")

        local tileset = loadTilesetInfo(source, firstgid)
        map.tilesets[tileset.name] = tileset

        for id = tileset.firstgid, tileset.firstgid + tileset.tileCount do
            tilesetMapping[id] = tileset
        end
    end

    print("loading map layer data")
    for layerNode in XML.iterNodeChildren(rootNode, "layer") do
        local layerName = string.upper(layerNode.attributes.name or "")
        assert(string.len(layerName) > 0, "Layer with empty name attribute found")

        local layerID = TileLayer[layerName]
        assert(layerID, "layer \"" .. layerName .. "\" is not one of the expected layers")

        print("loading layer " .. layerName)

        local index = 0
        for value in string.gmatch(XML.findNodeChild(layerNode, "data").text, "%d+") do
            local globalTileID = tonumber(value) or 0

            if globalTileID ~= 0 then
                local y = math.floor(index / width)
                local x = index - y * width

                local dFlip = bit.band(globalTileID, D_FLIP_MASK) ~= 0
                local hFlip = bit.band(globalTileID, H_FLIP_MASK) ~= 0
                local vFlip = bit.band(globalTileID, V_FLIP_MASK) ~= 0

                globalTileID = bit.band(globalTileID, NOFLIP_MASK)
                local tileset = tilesetMapping[globalTileID]
                assert(tileset)
                local tileID = globalTileID - tileset.firstgid + 1 -- relative to the tileset

                local tile = {
                    tileset = tileset,
                    id = tileID
                }

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
                    tile.r = -QUARTER_TURN
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

                if layerID == TileLayer.SCENERY then
                    map.walkable[y][x] = nil
                end

                if layerID == TileLayer.ENTITIES then
                    -- player, npc, item or other interactible
                    tile.x = x
                    tile.y = y
                    map.interactible[y][x] = tile
                else
                    -- simple layer
                    map.tiles[layerID][y][x] = tile
                end
            end
            index = index + 1
        end
    end

    print("loading map entities")
    local indexes = {}
    for _, entityID in pairs(EntityType) do
        indexes[entityID] = 1
    end

    local objectgroupNode = XML.findNodeChild(rootNode, "objectgroup")
    assert(objectgroupNode, "objects layer missing")

    for objectNode in XML.iterNodeChildren(objectgroupNode, "object") do
        local objectType = string.upper(objectNode.attributes.type or "")
        assert(string.len(objectType) > 0, "object with empty type attribute found")

        local entityType = EntityType[objectType]
        assert(entityType, "object type \"" .. objectType .. "\" is not one of the expected types")

        local y = tonumber(objectNode.attributes.y)
        local x = tonumber(objectNode.attributes.x)

        assert(y and x and y >= 0 and x >= 0)

        y = y / tileHeight
        x = x / tileWidth

        ---@type Entity
        local entity = map.interactible[y][x]
        assert(entity, "entity at coords x=" .. tostring(x) .. ", y=" .. tostring(y) .. " not found")

        local entityName = objectNode.attributes.name

        if entityName then
            -- name provided, make sure it is not a duplicate
            assert(map.entities[entityName] == nil, "duplicate entity with name \"" .. entityName .. "\" found")
        else
            -- no name provided, use entityType + autoIndex, for example NPC_23 or ITEM_12
            local index
            repeat
                index = indexes[entityType]
                entityName = objectType .. tostring(index)
                index = index + 1
            until map.entities[entityName] == nil

            indexes[entityType] = index
        end

        entity.type = entityType
        entity.name = entityName
        entity.properties = {}

        map.entities[entity.name] = entity

        if entity.type == EntityType.PLAYER then
            -- remove player entity from interactibles 2D table
            map.interactible[y][x] = nil
        end

        local propertiesNode = XML.findNodeChild(objectNode, "properties")
        -- load entity custom properties
        if propertiesNode then
            for propertyNode in XML.iterNodeChildren(propertiesNode, "property") do
                local name = propertyNode.attributes.name
                local value = propertyNode.attributes.value

                assert(name and string.len(name) > 0 and value)

                entity.properties[name] = value
            end
        end
    end

    return map
end

return module
