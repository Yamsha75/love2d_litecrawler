local DialogBox = require("dialogbox")

local module = {}

---@param gameState GameState
---@param object Object
---@return boolean moveIntoObject
function module.interactWithObject(gameState, object)
    local objectType = object.type

    if objectType == ObjectType.COIN then
        gameState.player.coins = gameState.player.coins + object.properties.value
        return true
    elseif objectType == ObjectType.ITEM then
        table.insert(gameState.inventory, object)
        return true
    elseif objectType == ObjectType.SIGN then
        DialogBox.newDialog(object.properties.text)
    elseif objectType == ObjectType.NPC then
        DialogBox.newDialog(object.properties.helloText or "<missing dialog>")
    end

    return false
end

return module
