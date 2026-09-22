local M = {}

function M.calcSpread(api, ammoCnt, basicInaccuracy)
    if (api:getFireMode() == AUTO) then
        return {0 , 0.6}
    elseif (api:getFireMode() == BURST) then
        return {0 , 1.2}
    else
        return {0 , 1.65}
    end
end

return M