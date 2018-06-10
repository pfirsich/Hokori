local utable = {}

function utable.keys(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, k)
    end
    return keys
end

function utable.count(tbl)
    local n = 0
    for k, v in pairs(tbl) do
        n = n + 1
    end
    return n
end

return utable
