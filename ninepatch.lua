---@class NinePatch
---@field x number
---@field y number
---@field w number
---@field h number
---@field x1 number
---@field x2 number
---@field y1 number
---@field y2 number
---@field lftW number
---@field midW number
---@field rgtW number
---@field topH number
---@field midH number
---@field botH number
---@field canvases love.Canvas[]
---@field quads love.Quad[]
local NinePatchMT = {}
NinePatchMT.__index = NinePatchMT

local class = {}

function class.isInstance(object)
    return getmetatable(object) == NinePatchMT
end

----Make sure image has filtering set to "nearest"/"nearest"
---@param image love.Image -- image should have wrap "repeat" set up
---@param x number -- x position of the patch
---@param y number -- y position of the patch
---@param w number -- width of the patch
---@param h number -- height of the patch
---@param lftW number -- left side edge width
---@param topH number? -- top side edge height; uses lftW if null
---@param rgtW number? -- right side edge width; uses lftW if null
---@param botH number? -- bottom side edge height; uses topH if null
---@return NinePatch
function class.new(image, x, y, w, h, lftW, topH, rgtW, botH)
    assert(type(x) == "number", "x must be a number")
    assert(type(y) == "number", "y must be a number")
    assert(type(w) == "number" and w > 0, "w must be a positive number")
    assert(type(h) == "number" and h > 0, "h must be a positive number")
    assert(type(lftW) == "number" and lftW >= 0, "lftW must be a non-negative number")
    assert(topH == nil or (type(topH) == "number" and topH >= 0), "topH must be null or a non-negative number")
    assert(rgtW == nil or (type(rgtW) == "number" and rgtW >= 0), "rgtW must be null or a non-negative number")
    assert(botH == nil or (type(botH) == "number" and botH >= 0), "botH must be null or a non-negative number")

    if not topH then topH = lftW end
    if not rgtW then rgtW = lftW end
    if not botH then botH = topH end

    local imgW, imgH = image:getDimensions()
    local midW = imgW - lftW - rgtW
    local midH = imgH - topH - botH
    assert(midW >= 0 and midH >= 0)

    -- quads/canvases order
    -- 1 2 3
    -- 4 5 6
    -- 7 8 9

    -- calculate coordinates of specific points in the original image
    local x0 = 0         -- left edge
    local x1 = x0 + lftW -- edge between first and second columns
    local x2 = x1 + midW -- edge between second and third columns

    local y0 = 0         -- top edge
    local y1 = y0 + topH -- edge between first and second rows
    local y2 = y1 + midH -- edge between second and third rows

    -- prepare quads that refer to each of the 9 parts of the image
    ---@type love.Quad[]
    local quads = {}
    quads[1] = love.graphics.newQuad(x0, y0, lftW, topH, imgW, imgH)
    quads[2] = love.graphics.newQuad(x1, y0, midW, topH, imgW, imgH)
    quads[3] = love.graphics.newQuad(x2, y0, rgtW, topH, imgW, imgH)
    quads[4] = love.graphics.newQuad(x0, y1, lftW, midH, imgW, imgH)
    quads[5] = love.graphics.newQuad(x1, y1, midW, midH, imgW, imgH)
    quads[6] = love.graphics.newQuad(x2, y1, rgtW, midH, imgW, imgH)
    quads[7] = love.graphics.newQuad(x0, y2, lftW, botH, imgW, imgH)
    quads[8] = love.graphics.newQuad(x1, y2, midW, botH, imgW, imgH)
    quads[9] = love.graphics.newQuad(x2, y2, rgtW, botH, imgW, imgH)

    -- prepare canvases onto which each part will be drawn; these canvases will be used as images to draw the full patch
    ---@type love.Canvas[]
    local canvases = {}
    canvases[1] = love.graphics.newCanvas(lftW, topH)
    canvases[2] = love.graphics.newCanvas(midW, topH)
    canvases[3] = love.graphics.newCanvas(rgtW, topH)
    canvases[4] = love.graphics.newCanvas(lftW, midH)
    canvases[5] = love.graphics.newCanvas(midW, midH)
    canvases[6] = love.graphics.newCanvas(rgtW, midH)
    canvases[7] = love.graphics.newCanvas(lftW, botH)
    canvases[8] = love.graphics.newCanvas(midW, botH)
    canvases[9] = love.graphics.newCanvas(rgtW, botH)

    -- draw each part of the image onto respective canvas
    for i = 1, 9 do
        canvases[i]:setWrap("repeat", "repeat")
        canvases[i]:setFilter("nearest", "nearest")
        love.graphics.setCanvas(canvases[i])
        love.graphics.draw(image, quads[i])
    end
    -- reset drawing target to screen
    love.graphics.setCanvas()

    -- calculate new coords and quads that use the canvases and will represent the size and position of the full patch
    midW = w - lftW - rgtW
    midH = h - topH - botH

    x0 = x
    x1 = x0 + lftW
    x2 = x1 + midW

    y0 = y
    y1 = y0 + topH
    y2 = y1 + midH

    -- now update the quads for use while drawing patch
    quads[1] = love.graphics.newQuad(0, 0, lftW, topH, canvases[1])
    quads[2] = love.graphics.newQuad(0, 0, midW, topH, canvases[2])
    quads[3] = love.graphics.newQuad(0, 0, rgtW, topH, canvases[3])
    quads[4] = love.graphics.newQuad(0, 0, lftW, midH, canvases[4])
    quads[5] = love.graphics.newQuad(0, 0, midW, midH, canvases[5])
    quads[6] = love.graphics.newQuad(0, 0, rgtW, midH, canvases[6])
    quads[7] = love.graphics.newQuad(0, 0, lftW, botH, canvases[7])
    quads[8] = love.graphics.newQuad(0, 0, midW, botH, canvases[8])
    quads[9] = love.graphics.newQuad(0, 0, rgtW, botH, canvases[9])

    ---@type NinePatch
    local instance = {
        x = x,
        y = y,
        w = w,
        h = h,
        x1 = x1,
        x2 = x2,
        y1 = y1,
        y2 = y2,
        lftW = lftW,
        midW = midW,
        rgtW = rgtW,
        topH = topH,
        midH = midH,
        botH = botH,
        canvases = canvases,
        quads = quads,
    }

    return setmetatable(instance, NinePatchMT)
end

---Update the position and size of the patch before drawing
---@param x number
---@param y number
---@param w number
---@param h number
function NinePatchMT:update(x, y, w, h)
    assert(type(x) == "number" and x >= 0, "x must be a non-negative number")
    assert(type(y) == "number" and y >= 0, "y must be a non-negative number")
    assert(type(w) == "number" and w > 0, "w must be a positive number")
    assert(type(h) == "number" and h > 0, "h must be a positive number")

    -- recalculate patch coords and sizes
    self.midW = w - self.lftW - self.rgtW
    self.midH = h - self.topH - self.botH

    self.x1 = x + self.lftW
    self.x2 = self.x1 + self.midW

    self.y1 = y + self.topH
    self.y2 = self.y1 + self.midH

    -- update quads
    local canvases = self.canvases
    local quads = self.quads
    quads[2]:setViewport(0, 0, self.midW, self.topH, canvases[2]:getDimensions())
    quads[4]:setViewport(0, 0, self.lftW, self.midH, canvases[4]:getDimensions())
    quads[5]:setViewport(0, 0, self.midW, self.midH, canvases[5]:getDimensions())
    quads[6]:setViewport(0, 0, self.rgtW, self.midH, canvases[6]:getDimensions())
    quads[8]:setViewport(0, 0, self.midW, self.botH, canvases[8]:getDimensions())
end

---Draw the patch. Preferably done once to a `love.Canvas` object and drawn from canvas to screen with normal
---`love.graphics.draw`
function NinePatchMT:draw()
    love.graphics.draw(self.canvases[1], self.quads[1], self.x, self.y)
    love.graphics.draw(self.canvases[2], self.quads[2], self.x1, self.y)
    love.graphics.draw(self.canvases[3], self.quads[3], self.x2, self.y)
    love.graphics.draw(self.canvases[4], self.quads[4], self.x, self.y1)
    love.graphics.draw(self.canvases[5], self.quads[5], self.x1, self.y1)
    love.graphics.draw(self.canvases[6], self.quads[6], self.x2, self.y1)
    love.graphics.draw(self.canvases[7], self.quads[7], self.x, self.y2)
    love.graphics.draw(self.canvases[8], self.quads[8], self.x1, self.y2)
    love.graphics.draw(self.canvases[9], self.quads[9], self.x2, self.y2)
end

return class
