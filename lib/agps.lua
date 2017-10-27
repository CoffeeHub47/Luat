--- 模块功能：星历更新服务
-- @module agps
-- @author 稀饭放姜
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2017.10.23
require "http"
module(..., package.seeall)

local AlmanacData = "/AlmanacData.dat"
-- 测试HTTP任务
function setup(timeout, upTime)
    sys.taskInit(function(timeout, upTime)
        while true do
            while not socket.isReady() do sys.wait(1000) end
            local code, head, data = http.request("GET", "download.openluat.com/9501-xingli/brdcGPD.dat_rda", timeout)
            if code == "200" then io.writefile(AlmanacData, common.binstohexs(data)) end
            log.info("agps.gpd:", common.binstohexs(data))
            sys.wait(upTime)
        end
    end, timeout, upTime)
end
