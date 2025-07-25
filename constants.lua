-- globals used across different modules

---@alias Table2D<T> table<integer, table<integer, T>> -- 2D table for mapping coordinates to type T

---@class GameState
---@field currentMap Map
---@field loadedMaps table<string, Map>
---@field player Player
---@field inventory Object[]
---@field progressTable table<string, any>

---@class Map
---@field width integer
---@field height integer
---@field tilesets table<string, Tileset>
---@field tileIDMapping table<integer, Tileset>
---@field layers table<TileLayer, Table2D<TileInfo>> -- info for tile rendering only; includes render order
---@field walkable Table2D<boolean> -- info for movement only
---@field objects Table2D<Object> -- info for objects/interactibles
---@field namedObjects table<string, Object> -- info for important named objects

---@class Tileset
---@field name string
---@field firstgid integer
---@field tileCount integer
---@field source string
---@field objectTypes table<integer, ObjectType> -- maps tileID (within tileset) to ObjectType
---@field defaultObjectProperties table<integer, table<string, any>> -- maps tileID (within tileset) to default properties table

---@class TileInfo -- info for tile rendering only
---@field tileset Tileset
---@field id integer tileID within the tileset
---@field x integer positionX
---@field y integer positionY
---@field r number rotation
---@field sx integer scaleX
---@field sy integer scaleY

---@class Object -- info about interactible tiles
---@field id integer
---@field name string?
---@field type ObjectType
---@field x integer
---@field y integer
---@field tile TileInfo
---@field properties table<string, any>

---@class Player : Object
---@field coins integer
---@field inventory Object[]

---@class NPC : Object
---@field helloText string
---@field helloAction string
---@field missionText string
---@field missionRequirement string
---@field missionCompleteAction string

---@class Mob : Object
---@field uniqueID string
---@field droppedCoins integer
---@field droppedItem string

---@enum TileLayer
TileLayer = {      -- map file layers; also rendering order
    GROUND = 1,    -- no special purpose
    SCENERY = 2,   -- tiles which block movement; can still be interactible
    DECOR = 3,     -- no special purpose
    FOREGROUND = 4 -- no special purpose
}

---@enum ObjectType
ObjectType = {
    PLAYER = 1,
    NPC = 2,
    MOB = 3,
    ITEM = 4,
    COIN = 5,
    DOOR = 6,
    PORTAL = 7,
    BREAKABLE = 8,
    CONTAINER = 9,
    SIGN = 10,
}

return { TileLayer = TileLayer, ObjectType = ObjectType }
