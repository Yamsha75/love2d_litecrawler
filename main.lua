Inspect = require("libraries.inspect")
MapLoader = require("maploader")
Sprites = require("sprites")

local inspect = Inspect.inspect

local SCALE = 2

local keyPresses = {}

---@type Map?
local map

---@type Entity?
local player

---@type table<integer, TileInfo>
local inventory = {}

function love.load()
    map = MapLoader.loadMapFromFile("town")
    assert(map)

    Sprites.load(map.tilesets, 16)

    love.window.setMode(Sprites.TILE_SIZE * (map.width + 3) * SCALE, Sprites.TILE_SIZE * map.height * SCALE, {})

    player = map.entities.player
    assert(player)

    return map, player
end

local directions = {
    up = { x = 0, y = -1 },
    right = { x = 1, y = 0 },
    down = { x = 0, y = 1 },
    left = { x = -1, y = 0 }
}
function love.update(dt)
    if not map or not player then return end

    for key, pressed in pairs(keyPresses) do
        if pressed then
            keyPresses[key] = false

            local d = directions[key]
            local x = player.x + d.x
            local y = player.y + d.y

            -- rotate sprite left or right
            if d.x > 0 then
                player.sx = 1
            elseif d.x < 0 then
                player.sx = -1
            end

            -- check boundaries
            if x < 0 or x >= map.width then
                return
            elseif y < 0 or y >= map.height then
                return
            end

            -- check interactibles
            ---@type Entity?
            local interactible = map.interactible[y][x]
            if interactible then
                local interactibleType = interactible.type

                if interactibleType == MapLoader.EntityType.PORTAL then
                    -- nothing for now
                elseif interactibleType == MapLoader.EntityType.ITEM then
                    table.insert(inventory, interactible)
                    map.entities[interactible.name] = nil
                    map.interactible[y][x] = nil

                    print(interactible.id)
                else
                    -- for other interactible types, skip movement
                    if interactibleType == MapLoader.EntityType.NPC then
                        -- guard bribe check
                        local bribed = false
                        if interactible.name == "forest_trapdoor_guard" then
                            for index, item in ipairs(inventory) do
                                if item.id == 54 then
                                    bribed = true
                                    print("Thanks for the coin, you can go through now.")

                                    table.remove(inventory, index)
                                    map.entities[interactible.name] = nil
                                    map.interactible[y][x] = nil
                                    break
                                end
                            end
                        end

                        if not bribed then
                            print(interactible.properties.text)
                        end
                    elseif interactibleType == MapLoader.EntityType.BREAKABLE then
                        local lootCode = interactible.properties.content
                        if string.find(lootCode, "item_") == 1 then
                            local itemID = tonumber(string.sub(lootCode, 6))
                            assert(itemID)

                            interactible.type = MapLoader.EntityType.ITEM
                            interactible.tileset = map.tilesets.items
                            interactible.id = itemID
                        end
                    elseif interactibleType == MapLoader.EntityType.TRAPDOOR then
                        interactible.type = MapLoader.EntityType.PORTAL
                        interactible.id = 104
                    elseif interactibleType == MapLoader.EntityType.SIGN then
                        print(interactible.properties.text)
                    end

                    -- skip movement
                    return
                end
            end

            -- check walls
            if map.walkable[y][x] == true then
                player.x = x
                player.y = y
            end
        end
    end
end

function love.draw()
    if not map or not player then return end

    love.graphics.scale(SCALE, SCALE)

    local layer
    local tile

    -- draw first 4 layers, skipping entities and foreground layer
    for layerID = 1, 4 do
        layer = map.tiles[layerID]
        for y = 0, map.height do
            for x = 0, map.width do
                tile = layer[y][x]

                if tile then
                    Sprites.draw(tile, x, y)
                end
            end
        end
    end

    -- draw entities other than player
    for _, entity in pairs(map.entities) do
        Sprites.draw(entity)
    end

    -- draw player
    Sprites.draw(player)

    -- draw foreground layer
    layer = map.tiles[5]
    for y = 0, map.height do
        for x = 0, map.width do
            tile = layer[y][x]

            if tile then
                Sprites.draw(tile, x, y)
            end
        end
    end

    -- draw inventory
    for index, item in ipairs(inventory) do
        Sprites.draw(item, map.width + 1, index)
    end
end

function love.keypressed(key, scancode, is_repeat)
    if is_repeat then return end

    if key == "escape" then
        love.event.quit()
    else
        if key == "up" or key == "right" or key == "down" or key == "left" then
            keyPresses[key] = true
        end
    end
end
