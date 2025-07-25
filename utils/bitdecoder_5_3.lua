---@version 5.3, 5.4
---@param tileID integer
---@return integer rawTileID, boolean diagFlip, boolean vertFlip, boolean horiFlip
return function(tileID)
    return tileID & 0x0FFFFFFF,     -- bits 1-28
        (tileID & 0x20000000) ~= 0, -- bit 30
        (tileID & 0x40000000) ~= 0, -- bit 31
        (tileID & 0x80000000) ~= 0  -- bit 32
end
