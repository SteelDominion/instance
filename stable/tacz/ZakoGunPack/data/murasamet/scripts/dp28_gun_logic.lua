local M = {}
--实现扳机延迟
function M.shoot(api)
    api:safeAsyncTask(function ()
        api:shootOnce(api:isShootingNeedConsumeAmmo())
        return false
    end,0.1*1000,0,1)
end
return M