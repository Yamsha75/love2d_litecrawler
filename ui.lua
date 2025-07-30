local SimpleQuad = require("simplequad")

local NinePatch = require("ninepatch")
local Tiles = require("tiles")

local SIDEPANEL_IMAGE_PATH = "assets/ui/tile_0013.png"
local DIALOG_BOX_IMAGE_PATCH = "assets/ui/tile_0018.png"
local ESCAPE_WINDOW_IMAGE_PATH = "assets/ui/tile_0001.png"

local ESCAPE_YES_TEXT = "Are you sure you want to quit?\n>YES     NO"
local ESCAPE_NO_TEXT = "Are you sure you want to quit?\n  YES   >NO"

local module = {}

---@class UIWindow
---@field x number
---@field y number
---@field background love.Canvas
---@field textX number
---@field textY number
---@field textLimit number
---@field text love.Text
---@field visible boolean

---@class SidePanel : UIWindow
---@field health number
---@field coins number
---@field inventory Object[]

---@class DialogBox : UIWindow
---@field message string
---@field choices string[]?
---@field choiceIndex integer?

---@class EscapeWindow : UIWindow
---@field yesSelected boolean

---@type SidePanel
local SidePanel

---@type DialogBox
local DialogBox

---@type EscapeWindow
local EscapeWindow

---@type number
local TilesScale

---@param imagePath string
---@param w number
---@param h number
---@param patchScale number
---@param ... number -- margins: left, top, right, bottom
local function preparePatchCanvas(imagePath, w, h, patchScale, ...)
    local image = love.graphics.newImage(imagePath)
    image:setFilter("nearest", "nearest")
    local canvas = love.graphics.newCanvas(w, h)
    canvas:setFilter("nearest", "nearest")
    local patch = NinePatch.new(image, -1, -1, w / patchScale + 2, h / patchScale + 2, ...)

    love.graphics.setCanvas(canvas)
    love.graphics.scale(patchScale)
    patch:draw()
    love.graphics.scale(1 / patchScale)
    love.graphics.setCanvas()

    return canvas
end

local function updateSidePanelText()
    assert(SidePanel)

    local s = string.format("Health: %d\nCoins: %d\nInventory:", SidePanel.health, SidePanel.coins)
    SidePanel.text:setf(s, SidePanel.textLimit, "left")

    return true
end

local function updateDialogBoxText()
    assert(DialogBox)

    local s = DialogBox.message

    if DialogBox.choices then
        for index, choice in ipairs(DialogBox.choices) do
            if index == DialogBox.choiceIndex then
                s = s .. string.format("\n>%s", choice)
            else
                s = s .. string.format("\n  %s", choice)
            end
        end
    end

    DialogBox.text:setf(s, DialogBox.textLimit, "left")

    return true
end

local function updateEscapeWindowText()
    assert(EscapeWindow)

    local s = EscapeWindow.yesSelected and ESCAPE_YES_TEXT or ESCAPE_NO_TEXT
    EscapeWindow.text:setf(s, EscapeWindow.textLimit, "center")

    return true
end

---@param sidePanelQuad SimpleQuad
---@param dialogBoxQuad SimpleQuad
---@param escapeWindowQuad SimpleQuad
---@param font love.Font
---@param sidePanelTextMargin number
---@param dialogBoxPanelTextMargin number
---@param escapeWindowTextMargin number
---@param patchScale number
---@param tilesScale number
function module.load(sidePanelQuad, dialogBoxQuad, escapeWindowQuad, font, sidePanelTextMargin, dialogBoxPanelTextMargin,
                     escapeWindowTextMargin, patchScale, tilesScale)
    assert(SimpleQuad.isInstance(sidePanelQuad))
    assert(SimpleQuad.isInstance(dialogBoxQuad))
    assert(SimpleQuad.isInstance(escapeWindowQuad))
    assert(font:typeOf("Font"))
    assert(type(sidePanelTextMargin) == "number" and sidePanelTextMargin >= 0)
    assert(type(dialogBoxPanelTextMargin) == "number" and dialogBoxPanelTextMargin >= 0)
    assert(type(escapeWindowTextMargin) == "number" and escapeWindowTextMargin >= 0)
    assert(type(patchScale) == "number" and patchScale > 0)
    assert(type(tilesScale) == "number" and tilesScale > 0)

    TilesScale = tilesScale

    local x, y, w, h

    x, y, w, h = sidePanelQuad:unpack()
    SidePanel = {
        x = x,
        y = y,
        background = preparePatchCanvas(SIDEPANEL_IMAGE_PATH, w, h, patchScale, 14, 13, 11, 17),
        textX = x + sidePanelTextMargin,
        textY = y + sidePanelTextMargin,
        textLimit = w - 2 * sidePanelTextMargin,
        text = love.graphics.newText(font),
        visible = true,
        health = 100,
        coins = 0,
        inventory = {},
    }
    updateSidePanelText()

    x, y, w, h = dialogBoxQuad:unpack()
    DialogBox = {
        x = x,
        y = y,
        background = preparePatchCanvas(DIALOG_BOX_IMAGE_PATCH, w, h, patchScale, 15),
        textX = x + dialogBoxPanelTextMargin,
        textY = y + dialogBoxPanelTextMargin,
        textLimit = w - 2 * dialogBoxPanelTextMargin,
        text = love.graphics.newText(font),
        visible = false,
        message = "test",
    }
    updateDialogBoxText()

    x, y, w, h = escapeWindowQuad:unpack()
    EscapeWindow = {
        x = x,
        y = y,
        background = preparePatchCanvas(ESCAPE_WINDOW_IMAGE_PATH, w, h, patchScale, 4),
        textX = x + escapeWindowTextMargin,
        textY = y + escapeWindowTextMargin,
        textLimit = w - 2 * escapeWindowTextMargin,
        text = love.graphics.newText(font),
        visible = false,
        yesSelected = false,
    }
    updateEscapeWindowText()
end

function module.drawSidePanel()
    assert(SidePanel)

    love.graphics.draw(SidePanel.background, SidePanel.x, SidePanel.y)

    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(0, 0, 0, 1)

    love.graphics.draw(SidePanel.text, SidePanel.textX, SidePanel.textY)

    love.graphics.setColor(r, g, b, a)
end

function module.drawDialogBox()
    assert(DialogBox)

    love.graphics.draw(DialogBox.background, DialogBox.x, DialogBox.y)

    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(0, 0, 0, 1)

    love.graphics.draw(DialogBox.text, DialogBox.textX, DialogBox.textY)

    love.graphics.setColor(r, g, b, a)
end

function module.drawEscapeWindow()
    assert(EscapeWindow)

    love.graphics.draw(EscapeWindow.background, EscapeWindow.x, EscapeWindow.y)
    love.graphics.draw(EscapeWindow.text, EscapeWindow.textX, EscapeWindow.textY)
end

function module.draw()
    assert(SidePanel)
    assert(DialogBox)
    assert(EscapeWindow)

    if SidePanel.visible then module.drawSidePanel() end
    if DialogBox.visible then module.drawDialogBox() end
    if EscapeWindow.visible then module.drawEscapeWindow() end
end

---@param visible boolean
function module.setSidePanelVisible(visible)
    assert(type(visible) == "boolean")
    assert(SidePanel)

    if visible == SidePanel.visible then return false end

    SidePanel.visible = visible

    return true
end

---@param visible boolean
function module.setDialogBoxVisible(visible)
    assert(type(visible) == "boolean")
    assert(DialogBox)

    if visible == DialogBox.visible then return false end

    DialogBox.visible = visible

    return true
end

---@param visible boolean
function module.setEscapeWindowVisible(visible)
    assert(type(visible) == "boolean")
    assert(EscapeWindow)

    if visible == EscapeWindow.visible then return false end

    EscapeWindow.visible = visible

    return true
end

function module.isSidePanelVisible()
    assert(SidePanel)

    return SidePanel.visible
end

function module.isDialogBoxVisible()
    assert(DialogBox)

    return DialogBox.visible
end

function module.isEscapeWindowVisible()
    assert(EscapeWindow)

    return EscapeWindow.visible
end

---@param health number
function module.updateHealth(health)
    assert(type(health) == "number")
    assert(SidePanel)

    SidePanel.health = health

    return updateSidePanelText()
end

---@param coins number
function module.updateCoins(coins)
    assert(type(coins) == "number")
    assert(SidePanel)

    SidePanel.coins = coins

    return updateSidePanelText()
end

---@param inventory Object[]
function module.updateInventory(inventory)
    assert(type(inventory) == "table")
    assert(SidePanel)

    SidePanel.inventory = inventory

    return updateSidePanelText()
end

---@param text string
---@param choices string[]?
function module.startNewDialog(text, choices)
    assert(type(text) == "string")
    assert(choices == nil or (type(choices) == "table" and #choices >= 1))
    assert(DialogBox)

    DialogBox.visible = true
    DialogBox.message = text

    if choices then
        DialogBox.choices = choices
        DialogBox.choiceIndex = 1
    else
        DialogBox.choices = nil
        DialogBox.choiceIndex = nil
    end

    return updateDialogBoxText()
end

---@param reverse boolean?
function module.incrementDialogBoxChoice(reverse)
    assert(reverse == nil or type(reverse) == "boolean")
    assert(DialogBox)

    if not DialogBox.choices or #DialogBox.choices <= 1 then return false end

    local choiceIndex = DialogBox.choiceIndex + (not reverse and 1 or -1)

    if choiceIndex > #DialogBox.choices then
        choiceIndex = 1
    elseif choiceIndex < 1 then
        choiceIndex = #DialogBox.choices
    end

    DialogBox.choiceIndex = choiceIndex

    return updateDialogBoxText()
end

---@return string? choice, integer? choiceIndex
function module.endDialog()
    assert(DialogBox)

    if not DialogBox.visible then return end

    DialogBox.visible = false

    if not DialogBox.choices then return end

    return DialogBox.choices[DialogBox.choiceIndex], DialogBox.choiceIndex
end

function module.openEscapeWindow()
    assert(EscapeWindow)

    EscapeWindow.visible = true
    EscapeWindow.yesSelected = true
    return updateEscapeWindowText()
end

---@return boolean yesSelected
function module.getEscapeWindowChoice()
    assert(EscapeWindow)

    return EscapeWindow.yesSelected
end

---@param yesSelected boolean
function module.updateEscapeWindowChoice(yesSelected)
    assert(type(yesSelected) == "boolean")
    assert(EscapeWindow)

    if EscapeWindow.yesSelected == yesSelected then return false end

    EscapeWindow.yesSelected = yesSelected
    return updateEscapeWindowText()
end

return module
