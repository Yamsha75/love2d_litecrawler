local UI = require("ui")

local module = {}

---@param gameState GameState
---@param object Object
---@return boolean moveIntoObject
function module.interactWithObject(gameState, object)
    local objectType = object.type

    if objectType == ObjectType.COIN then
        gameState.player.coins = gameState.player.coins + object.properties.value
        UI.updateCoins(gameState.player.coins)
        return true
    elseif objectType == ObjectType.ITEM then
        table.insert(gameState.inventory, object)
        UI.updateInventory(gameState.inventory)
        return true
    elseif objectType == ObjectType.SIGN then
        UI.startNewDialog(object.properties.text)
    elseif objectType == ObjectType.NPC then
        UI.startNewDialog(object.properties.helloText or "<missing dialog>")
    end

    return false
end

return module
