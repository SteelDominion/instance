local M = {}

function M.calcSpread(api, ammoCnt, basicInaccuracy)
    if (api:getAttachment("SCOPE") == "murasamet:scope_pgo_7") then
        local angle = 0.21 * math.pi
        return {0 , 0.85}
    else
        local angle = 0.25 * math.pi
        return {0 , 0}
    end
end

return M