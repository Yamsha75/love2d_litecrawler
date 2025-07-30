---@class SimpleQuad
---@field x number
---@field y number
---@field w number
---@field h number
local SimpleQuadMT = {}
SimpleQuadMT.__index = SimpleQuadMT

local class = {}

function class.isInstance(object)
    return getmetatable(object) == SimpleQuadMT
end

---@param x number
---@param y number
---@param w number
---@param h number
function class.new(x, y, w, h)
    assert(type(x) == "number")
    assert(type(y) == "number")
    assert(type(w) == "number")
    assert(type(h) == "number")

    local instance = {
        x = x,
        y = y,
        w = w,
        h = h
    }

    return setmetatable(instance, SimpleQuadMT)
end

function SimpleQuadMT:unpack()
    return self.x, self.y, self.w, self.h
end

function SimpleQuadMT:getPosition()
    return self.x, self.y
end

function SimpleQuadMT:getSize()
    return self.w, self.h
end

return class
