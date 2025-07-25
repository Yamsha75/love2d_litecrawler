local NinePatch = require("ninepatch")

local PATCH_IMAGE_PATH = "assets/ui/tile_0018.png"
local DEFAULT_FONT_PATH = "assets/fonts/Metamorphous-Regular.ttf"

---@type love.Font
local FONT

local CANVAS

local BOX_X = 0
local BOX_Y = 0

local TEXT_X = 0
local TEXT_Y = 0
local TEXT_W = 0

local TEXT_SCALE = 1

local isDialogBoxShown = false
local boxText = ""

---@type string[]?
local boxChoices

local boxSelectedChoice = 1

local module = {}

---@param x number
---@param y number
---@param w number
---@param h number
---@param textMargin? number
---@param textScale? number
---@param font? love.Font
function module.load(x, y, w, h, textMargin, textScale, font)
    BOX_MARGIN = textMargin or 0
    TEXT_SCALE = textScale or 1

    if font then
        FONT = font
    else
        FONT = love.graphics.newFont(DEFAULT_FONT_PATH, 8, nil, 2)
    end

    BOX_X = x
    BOX_Y = y

    TEXT_X = (x + textMargin) / textScale
    TEXT_Y = (y + textMargin) / textScale
    TEXT_W = (x + w - 2 * textMargin) / textScale

    local image = love.graphics.newImage(PATCH_IMAGE_PATH)
    image:setFilter("nearest", "nearest")

    local patch = NinePatch.create(image, 0, 0, w, h, 15, 12, 13, 12)

    CANVAS = love.graphics.newCanvas(w, h)
    CANVAS:setFilter("nearest", "nearest")

    love.graphics.setCanvas(CANVAS)
    NinePatch.draw(patch)
    love.graphics.setCanvas()
end

---@return boolean
function module.isDialogBoxShown()
    return isDialogBoxShown
end

---@param text string
---@param choices? string[]
function module.newDialog(text, choices)
    isDialogBoxShown = true
    boxText = text
    boxChoices = choices
    boxSelectedChoice = 1

    return true
end

---@return boolean success
function module.finishDialog()
    if isDialogBoxShown then
        isDialogBoxShown = false
        return true
    else
        return false
    end
end

---@param reverse? boolean
function module.incrementDialogBoxChoice(reverse)
    if not boxChoices or #boxChoices <= 1 then return false end

    if not reverse then
        boxSelectedChoice = boxSelectedChoice + 1
        if boxSelectedChoice > #boxChoices then boxSelectedChoice = 1 end
    else
        boxSelectedChoice = boxSelectedChoice - 1
        if boxSelectedChoice < 1 then boxSelectedChoice = #boxChoices end
    end

    return true
end

---@return integer?, string?
function module.getDialogBoxChoice()
    if not boxChoices then return end

    return boxSelectedChoice, boxChoices[boxSelectedChoice]
end

function module.draw()
    if isDialogBoxShown then
        -- draw background box
        love.graphics.draw(CANVAS, BOX_X, BOX_Y)

        if boxText then
            -- use black color and scale text
            love.graphics.setColor(0, 0, 0, 1)
            if TEXT_SCALE ~= 1 then love.graphics.scale(TEXT_SCALE, TEXT_SCALE) end

            local textBuffer = boxText
            if boxChoices then
                for index, choiceText in ipairs(boxChoices) do
                    if index == boxSelectedChoice then
                        textBuffer = textBuffer .. string.format("\n>%s", choiceText)
                    else
                        textBuffer = textBuffer .. string.format("\n  %s", choiceText)
                    end
                end
            end
            love.graphics.printf(textBuffer, FONT, TEXT_X, TEXT_Y, TEXT_W, "left")

            -- reset color and reset scale
            love.graphics.setColor(1, 1, 1, 1)
            if TEXT_SCALE ~= 1 then love.graphics.scale(1 / TEXT_SCALE, 1 / TEXT_SCALE) end
        end
    end
end

return module
