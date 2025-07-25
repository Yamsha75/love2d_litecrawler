---@param n integer
---@return table<integer, integer>
local function bitsToTable(n)
    -- based on https://stackoverflow.com/a/9080080
    -- returns a table of bits, least significant first.
    local result = {} -- will contain the bits

    while n > 0 do
        local remainder = math.fmod(n, 2)
        table.insert(result, remainder)
        n = (n - remainder) / 2
    end

    return result
end

---@version 5.1
---@param tileID integer
---@return integer rawTileID, boolean diagFlip, boolean vertFlip, boolean horiFlip
return function(tileID)
    local integral, fractional = math.modf(tileID / 0x10000000)
    local bits = bitsToTable(integral)

    return fractional * 0x10000000, -- bits 1-28
        bits[2] == 1,              -- bit 30
        bits[3] == 1,              -- bit 31
        bits[4] == 1               -- bit 32
end
