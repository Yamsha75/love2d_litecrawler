local Inspect = require("libraries.inspect")

local Constants = require("constants")
local MapLoader = require("maploader")
local Tiles = require("tiles")
local DialogBox = require("dialogbox")
local Interactions = require("interactions")

---@type GameState
local gameState

---@type table<string, boolean>
local keyPresses = {}

-- tile size * tilesCount * scale
local windowWidth = Tiles.TILE_SIZE * 12 * Tiles.SCALE
local windowHeight = Tiles.TILE_SIZE * 9 * Tiles.SCALE

local TEXT_ITEMS = {}

function love.load()
    love.window.setMode(windowWidth, windowHeight, {})

    local map, player = MapLoader.loadMapFromFile("town")
    assert(map and player)

    player.coins = 0
    player.inventory = {}

    ---@type GameState
    gameState = {
        currentMap = map,
        loadedMaps = { default = map },
        player = player,
        inventory = {},
        progressTable = {},
    }

    Tiles.load(map.tilesets, 16)
    Tiles.updateCamera(map, player)

    DialogBox.load(0, Tiles.TILE_SIZE * (9 - 3), Tiles.TILE_SIZE * 9, Tiles.TILE_SIZE * 3, 8, 0.5)
    DialogBox.newDialog("Game: choose your gender", { "boy", "girl" })
end

local moveDirections = {
    up = { x = 0, y = -1 },
    right = { x = 1, y = 0 },
    down = { x = 0, y = 1 },
    left = { x = -1, y = 0 }
}
---@param dt number
function love.update(dt)
    if not gameState then return end

    local now = love.timer.getTime()
    for id, textItem in pairs(TEXT_ITEMS) do
        if now > textItem.removeTick then
            TEXT_ITEMS[id] = nil
        end
    end

    if DialogBox.isDialogBoxShown() then
        if keyPresses["return"] then
            local choiceIndex, choiceText = DialogBox.getDialogBoxChoice()

            if choiceText == "girl" then
                gameState.player.tile.id = 3
            end

            DialogBox.finishDialog()
        elseif keyPresses.up then
            DialogBox.incrementDialogBoxChoice(true)
        elseif keyPresses.down then
            DialogBox.incrementDialogBoxChoice()
        end

        for key, _ in pairs(keyPresses) do
            keyPresses[key] = false
        end
    else
        for key, _ in pairs(moveDirections) do
            if keyPresses[key] then
                keyPresses[key] = false

                local d = moveDirections[key]
                local x = gameState.player.x + d.x
                local y = gameState.player.y + d.y

                -- rotate sprite left or right
                if d.x > 0 then
                    gameState.player.tile.sx = 1
                elseif d.x < 0 then
                    gameState.player.tile.sx = -1
                end

                -- check boundaries
                if x < 0 or x >= gameState.currentMap.width then
                    return
                elseif y < 0 or y >= gameState.currentMap.height then
                    return
                end

                -- check interactibles
                ---@type Object?
                local object = gameState.currentMap.objects[y][x]
                if object then
                    local moveIntoObject = Interactions.interactWithObject(gameState, object)
                    if not moveIntoObject then return end

                    -- local objectType = object.type

                    -- if objectType == ObjectType.COIN then
                    --     map.objects[y][x] = nil
                    --     player.coins = player.coins + object.properties.value
                    -- elseif objectType == ObjectType.ITEM then
                    --     table.insert(player.inventory, object)
                    --     map.objects[y][x] = nil
                    -- elseif objectType == ObjectType.PORTAL then
                    --     -- nothing for now
                    -- else
                    -- for other interactible types, skip movement
                    -- if objectType == ObjectType.NPC then
                    --     -- guard bribe check
                    --     local bribed = false
                    --     if object.uniqueName == "forest_trapdoor_guard" then
                    --         for index, item in ipairs(player.inventory) do
                    --             if item.id == 54 then
                    --                 bribed = true
                    --                 print("Thanks for the coin, you can go through now.")

                    --                 table.remove(player.inventory, index)
                    --                 map.objects[object.uniqueName] = nil
                    --                 map.interactible[y][x] = nil
                    --                 break
                    --             end
                    --         end
                    --     end

                    --     if not bribed then
                    --         print(object.properties.text)
                    --     end
                    -- elseif objectType == ObjectType.BREAKABLE then
                    --     local lootCode = object.properties.content
                    --     if string.find(lootCode, "item_") == 1 then
                    --         local itemID = tonumber(string.sub(lootCode, 6))
                    --         assert(itemID)

                    --         object.type = ObjectType.ITEM
                    --         object.tileset = map.tilesets.items
                    --         object.id = itemID
                    --     end
                    --[[ else]]
                    -- if objectType == ObjectType.SIGN then
                    --     isDialogBoxShowing = true
                    --     DialogBox.setDialogBoxText(object.properties.text)

                    -- local objectId = object.id
                    -- local text = object.properties.text

                    -- TEXT_ITEMS[objectId] =
                    -- {
                    --     x = object.x,
                    --     y = object.y,
                    --     text = love.graphics.newText(Tiles.BLOCK_FONT, text),
                    --     removeTick = love.timer.getTime() + 2.5,
                    -- }
                    -- end

                    -- skip movement
                    -- return
                    --     end
                end

                -- check walls
                if gameState.currentMap.walkable[y][x] == true then
                    gameState.player.x = x
                    gameState.player.y = y
                end
            end
        end
        Tiles.updateCamera(gameState.currentMap, gameState.player)
    end
end

function love.draw()
    if not gameState then return end

    love.graphics.scale(Tiles.SCALE, Tiles.SCALE)

    Tiles.drawMap(gameState.currentMap, gameState.player)

    love.graphics.setColor(1, 1, 1, 1)

    DialogBox.draw()

    Tiles.drawInventory(gameState.player, gameState.currentMap.width)
    Tiles.drawTexts(TEXT_ITEMS)
end

function love.keypressed(key, scancode, is_repeat)
    if is_repeat then return end

    if key == "escape" and love.system.getOS() ~= "web" then
        love.event.quit()
    elseif key == "return" then
        keyPresses[key] = true
    else
        if key == "up" or key == "right" or key == "down" or key == "left" then
            keyPresses[key] = true
        end
    end
end
