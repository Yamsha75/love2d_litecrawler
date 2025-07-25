---@generic K, V
---@param t table<K, V>
---@return table<K, V>
function table.shallowCopy(t)
    local copy = {}

    for key, value in pairs(t) do
        copy[key] = value
    end

    return copy
end
