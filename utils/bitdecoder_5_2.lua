---@version 5.2
---@param tileID integer
---@return integer rawTileID, boolean diagFlip, boolean vertFlip, boolean horiFlip
return function(tileID)
    return bit32.band(tileID, 0x0FFFFFFF),       -- bits 1-28
        bit32.band(tileID, 0x20000000) ~= 0,     -- bit 30
        bit32.band(tileID, 0x40000000) ~= 0,     -- bit 31
        bit32.band(tileID, 0x80000000) ~= 0      -- bit 32
end
