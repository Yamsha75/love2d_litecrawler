Iffy = require("libraries.iffy")

local TILE_SIZE = 16
local TILE_HALFSIZE = TILE_SIZE * 0.5

local module = { TILE_SIZE = TILE_SIZE, TILE_HALFSIZE = TILE_HALFSIZE }

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
end

---@param drawable TileInfo
---@param x integer?
---@param y integer?
function module.draw(drawable, x, y)
    x = (x or drawable.x) * TILE_SIZE + TILE_HALFSIZE
    y = (y or drawable.y) * TILE_SIZE + TILE_HALFSIZE

    Iffy.draw(drawable.tileset.name, drawable.id, x, y, drawable.r, drawable.sx or 1, drawable.sy or 1, TILE_HALFSIZE,
        TILE_HALFSIZE)
end

return module
