local slaxml = require("libraries.slaxml")

local module = {}

---@class XmlNode
---@field name string
---@field attributes table<string, string>?
---@field text string?
---@field children XmlNode[]?
---@field parent XmlNode?

---@param node XmlNode
---@param childName string
---@return XmlNode|false
function module.findNodeChild(node, childName)
    for _, child in ipairs(node.children or {}) do
        if child.name == childName then
            return child
        end
    end

    return false
end

---@param node XmlNode
---@param childName string
---@return fun():XmlNode?
function module.iterNodeChildren(node, childName)
    local t = node.children or {}
    local i = 0
    local n = #t

    return function()
        while i <= n do
            i = i + 1

            local childNode = t[i]
            if childNode and childNode.name == childName then
                return childNode
            end
        end
    end
end

---@param node XmlNode
---@param childName string
---@return XmlNode[]
function module.findNodeChildren(node, childName)
    local children = {}

    local i = 1
    for child in module.iterNodeChildren(node, childName) do
        children[i] = child
        i = i + 1
    end

    return children
end

---@param xmlContent string
---@return XmlNode
function module.loadFromString(xmlContent)
    local rootNode
    local thisNode

    local parserConfig = {}

    -- local doNothing = function() end

    -- parserConfig.pi = doNothing
    -- parserConfig.comment = doNothing

    function parserConfig.startElement(name)
        if not rootNode then
            local node = { name = name }
            rootNode = node
            thisNode = node
        else
            local node = { name = name, parent = thisNode }
            if thisNode.children then
                table.insert(thisNode.children, node)
            else
                thisNode.children = { node }
            end
            thisNode = node
        end
    end

    function parserConfig.attribute(name, value)
        if thisNode.attributes then
            thisNode.attributes[name] = value
        else
            thisNode.attributes = { [name] = value }
        end
    end

    function parserConfig.closeElement(name)
        thisNode = thisNode.parent
    end

    function parserConfig.text(text)
        thisNode.text = text
    end

    slaxml:parser(parserConfig):parse(xmlContent, { stripWhitespace = true })

    return rootNode
end

return module
