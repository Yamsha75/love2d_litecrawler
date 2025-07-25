local Iffy = require("libraries.iffy")

-- initial values; ovewritten at module.load
local SCALE = 5
local TILE_SIZE = 16
local TILE_HALFSIZE = TILE_SIZE * 0.5

---@type love.Font
local BLOCK_FONT

local module = { TILE_SIZE = TILE_SIZE, TILE_HALFSIZE = TILE_HALFSIZE, SCALE = SCALE, BLOCK_FONT = BLOCK_FONT }

-- number of tiles around center to draw
local CAMERA_RANGE = 4

-- range of tile coordinates for drawing
local CamMinX = 0
local CamMaxX = 0
local CamMinY = 0
local CamMaxY = 0

-- center tile coordinates
local CamX = 0
local CamY = 0

---@param tilesets table<string, Tileset>
---@param tileSize? integer
function module.load(tilesets, tileSize)
    if tileSize then
        TILE_SIZE = tileSize
        TILE_HALFSIZE = tileSize / 2
    end

    for _, tileset in pairs(tilesets) do
        Iffy.newTileSet(tileset.name, tileset.source, TILE_SIZE, TILE_SIZE)
        Iffy.getImage(tileset.name):setFilter("nearest")
    end

    -- BLOCK_FONT = love.graphics.newFont("assets/fonts/Kenney Blocks.ttf", 8)
    BLOCK_FONT = love.graphics.newFont("assets/fonts/Metamorphous-Regular.ttf", 20, "normal", 0.75)
    -- BLOCK_FONT:setFilter("nearest", "nearest")
end

---@param map Map
---@param player Player
function module.updateCamera(map, player)
    CamMinX = math.max(0, player.x - CAMERA_RANGE)
    CamMaxX = math.min(map.width, player.x + CAMERA_RANGE)

    CamMinY = math.max(0, player.y - CAMERA_RANGE)
    CamMaxY = math.min(map.height, player.y + CAMERA_RANGE)

    CamX = player.x
    CamY = player.y
end

---@param drawable TileInfo
---@param x? integer
---@param y? integer
---@param semitransparent? boolean
function module.draw(drawable, x, y, semitransparent)
    x = ((x or drawable.x) - CamX + CAMERA_RANGE) * TILE_SIZE + TILE_HALFSIZE
    y = ((y or drawable.y) - CamY + CAMERA_RANGE) * TILE_SIZE + TILE_HALFSIZE

    if semitransparent then
        love.graphics.setColor(1, 1, 1, 0.5)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    Iffy.draw(drawable.tileset.name, drawable.id, x, y, drawable.r, drawable.sx or 1, drawable.sy or 1, TILE_HALFSIZE,
        TILE_HALFSIZE)
end

---@param map Map
---@param player Player
function module.drawMap(map, player)
    if not map or not player then return end

    local layer, tile

    -- draw first 3 layers, skipping foreground layer
    for layerID = 1, 3 do
        layer = map.layers[layerID]
        -- for y = 0, map.height do
        -- for x = 0, map.width do
        for y = CamMinY, CamMaxY do
            for x = CamMinX, CamMaxX do
                tile = layer[y][x]
                if tile then
                    module.draw(tile, x, y)
                end
            end
        end
    end

    -- draw objects
    local objects = map.objects
    local object
    -- for y = 0, map.height do
    -- for x = 0, map.width do
    for y = CamMinY, CamMaxY do
        for x = CamMinX, CamMaxX do
            object = objects[y][x] --[[@as Object]]
            if object then
                module.draw(object.tile, object.x, object.y)
            end
        end
    end

    -- draw player
    module.draw(player.tile, player.x, player.y)

    -- draw foreground layer
    layer = map.layers[TileLayer.FOREGROUND]
    -- for y = 0, map.height do
    -- for x = 0, map.width do
    for y = CamMinY, CamMaxY do
        for x = CamMinX, CamMaxX do
            tile = layer[y][x]

            if tile then
                module.draw(tile, x, y, x == player.x and y == player.y)
            end
        end
    end
end

---@param player Player
---@param mapWidth integer
function module.drawInventory(player, mapWidth)
    local inventoryTextX = (2 * CAMERA_RANGE + 1) * TILE_SIZE * SCALE + 6 * SCALE
    local text = string.format("Health: %d\nCoins: %d\nItems:", 100, player.coins)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.scale(1 / SCALE, 1 / SCALE)

    love.graphics.printf(text, BLOCK_FONT, inventoryTextX, 6 * SCALE, TILE_SIZE * 3 * SCALE, "left")

    love.graphics.scale(SCALE, SCALE)

    for index, item in ipairs(player.inventory) do
        local offsetY, offsetX = math.modf((index - 1) / 3)
        module.draw(item.tile, CamX + CAMERA_RANGE + offsetX * 3 + 1, CamY - CAMERA_RANGE + offsetY + 2.5, false)
    end
end

---@param textInfos table<string, any>
function module.drawTexts(textInfos)
    for _, textInfo in pairs(textInfos) do
        local text = textInfo.text --[[@as love.Text]]
        local width = text:getWidth()
        local height = text:getHeight()

        local x = (textInfo.x + 0.5) * TILE_SIZE - width / 2
        local y = (textInfo.y) * TILE_SIZE

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", x, y, width, height)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(textInfo.text, (textInfo.x + 0.5) * TILE_SIZE - width / 2, (textInfo.y) * TILE_SIZE, 0, 1, 1)
    end
end

return module
