-- libraries
local Inspect = require("libraries.inspect")

local Constants = require("constants")
local SimpleQuad = require("simplequad")

local Tiles = require("tiles")
local UI = require("ui")

local MapLoader = require("maploader")
local Interactions = require("interactions")


-- constants
local MAIN_FONT_PATH = "assets/fonts/Metamorphous-Regular.ttf"

-- globals
---@type love.Font
local MainFont

---@type GameState
local GameState

---@type table<string, boolean>
local KeyPresses = {}

-- tile size * tilesCount * scale
local WindowWidth = Tiles.TILE_SIZE * 12 * Tiles.SCALE
local WindowHeight = Tiles.TILE_SIZE * 9 * Tiles.SCALE

function love.load()
    -- initialize window
    love.window.setMode(WindowWidth, WindowHeight, {})

    -- initialize font
    MainFont = love.graphics.newFont(MAIN_FONT_PATH, 16)

    -- load map and initialize GameState
    local map, player = MapLoader.loadMapFromFile("town")
    assert(map and player)

    player.coins = 0
    player.inventory = {}

    ---@type GameState
    GameState = {
        currentMap = map,
        loadedMaps = { default = map },
        player = player,
        inventory = {},
        progressTable = {},
    }

    -- initialize other modules
    Tiles.load(map.tilesets, 16)
    Tiles.updateCamera(map, player)

    local tileSizeScaled = Tiles.TILE_SIZE * Tiles.SCALE

    local sidePanelQuad = SimpleQuad.new(9 * tileSizeScaled, 0, 3 * tileSizeScaled, 9 * tileSizeScaled)
    local dialogBoxQuad = SimpleQuad.new(0, 6 * tileSizeScaled, 9 * tileSizeScaled, 3 * tileSizeScaled)
    local escapeWindowQuad = SimpleQuad.new(2 * tileSizeScaled, 3 * tileSizeScaled, 5 * tileSizeScaled, tileSizeScaled)

    UI.load(sidePanelQuad, dialogBoxQuad, escapeWindowQuad, MainFont, 20, 24, 20, 4, Tiles.SCALE)

    UI.startNewDialog("Game: choose your gender", { "boy", "girl" })
end

local moveDirections = {
    up = { x = 0, y = -1 },
    right = { x = 1, y = 0 },
    down = { x = 0, y = 1 },
    left = { x = -1, y = 0 }
}
---@param dt number
function love.update(dt)
    if not GameState then return end

    if UI.isEscapeWindowVisible() then
        if KeyPresses["return"] then
            if UI.getEscapeWindowChoice() == true then
                love.event.quit()
            else
                UI.setEscapeWindowVisible(false)
            end
        elseif KeyPresses["left"] then
            UI.updateEscapeWindowChoice(true)
        elseif KeyPresses["right"] then
            UI.updateEscapeWindowChoice(false)
        end
    elseif UI.isDialogBoxVisible() then
        if KeyPresses["return"] then
            local choiceText = UI.endDialog()

            if choiceText == "girl" then
                GameState.player.tile.id = 3
            end
        elseif KeyPresses["up"] then
            UI.incrementDialogBoxChoice(true)
        elseif KeyPresses["down"] then
            UI.incrementDialogBoxChoice(false)
        end
    else
        for key, _ in pairs(moveDirections) do
            if KeyPresses[key] then
                KeyPresses[key] = false

                local d = moveDirections[key]
                local x = GameState.player.x + d.x
                local y = GameState.player.y + d.y

                -- rotate sprite left or right
                if d.x > 0 then
                    GameState.player.tile.sx = 1
                elseif d.x < 0 then
                    GameState.player.tile.sx = -1
                end

                -- check boundaries
                if x < 0 or x >= GameState.currentMap.width then
                    return
                elseif y < 0 or y >= GameState.currentMap.height then
                    return
                end

                local moveInto = true

                -- check interactibles
                ---@type Object?
                local object = GameState.currentMap.objects[y][x]
                if object then
                    -- object may be walked into after interaction or may block movement
                    moveInto = Interactions.interactWithObject(GameState, object)
                end

                -- check walls
                if moveInto and GameState.currentMap.walkable[y][x] == true then
                    GameState.player.x = x
                    GameState.player.y = y
                    Tiles.updateCamera(GameState.currentMap, GameState.player)
                end

                -- stop processing other directions in this update cycle to avoid unwanted behaviour
                break
            end
        end
    end

    -- clean up key presses
    for key, _ in pairs(KeyPresses) do
        KeyPresses[key] = false
    end
end

function love.draw()
    if not GameState then return end

    love.graphics.scale(Tiles.SCALE, Tiles.SCALE)

    Tiles.drawMap(GameState.currentMap, GameState.player)

    love.graphics.scale(1 / Tiles.SCALE, 1 / Tiles.SCALE)

    UI.draw()
end

function love.keypressed(key, scancode, is_repeat)
    if is_repeat then return end

    if key == "escape" then
        if not UI.isEscapeWindowVisible() and love.system.getOS() ~= "web" then
            UI.openEscapeWindow()
        end
    elseif key == "return" then
        KeyPresses[key] = true
    elseif key == "up" or key == "right" or key == "down" or key == "left" then
        KeyPresses[key] = true
    end
end
