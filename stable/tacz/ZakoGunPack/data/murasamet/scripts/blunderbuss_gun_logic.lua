local M = {}

function M.shoot(api)
    if (api:isAiming() == true) then
        return false
    else
        api:shootOnce(api:isShootingNeedConsumeAmmo()api:getAimingProgress())
    end
end

return M