-- used to decode flip flags used by Tiled editor, as bitwise operations are not built-in in Lua 5.1
-- bit 32 / mask 0x80000000 - horizontal flip
-- bit 31 / mask 0x40000000 - vertical flip
-- bit 30 / mask 0x20000000 - diagonal flip
-- bit 29 / mask 0x10000000 - ignored for orthogonal maps
-- bits 1-28 / mask 0x0FFFFFFF - actual tile id

local module = {}

-- bitwise operations are done using differently depending on Lua version
local VERSION = _G._VERSION
local isJIT = (_G["jit"] ~= nil)

if isJIT then
    -- LuaJIT has a built-in bitwise library "bit"
    module.decodeTileID = require("utils.bitdecoder_jit")
elseif VERSION == "Lua 5.1" then
    -- Lua 5.1 has no bitwise operations; simple math operations are used
    module.decodeTileID = require("utils.bitdecoder_5_1")
elseif VERSION == "Lua 5.2" then
    -- Lua 5.2 has a built-in bitwise library "bit32"
    module.decodeTileID = require("utils.bitdecoder_5_2")
else
    -- Lua 5.3 and further has built-in bitwise operators
    module.decodeTileID = require("utils.bitdecoder_5_3")
end

return module
