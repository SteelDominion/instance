local M = {}

function M.calcSpread(api, ammoCnt, basicInaccuracy)
    local whatcanisay = (math.random(100)/100) * math.pi * (-1)^(math.random(2))
    local manbaout = (math.random(100)/100) * math.pi * (-1)^(math.random(2))
    if (context:isCrawl()   ) then
        return {0.01*math.sin(whatcanisay), 0.01*math.sin(manbaout)}
    else
        return {math.sin(whatcanisay), math.sin(manbaout)}
    end
end

return M

--烂尾（