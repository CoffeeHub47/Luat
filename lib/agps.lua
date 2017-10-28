--- 模块功能：星历更新服务
-- @module agps
-- @author 稀饭放姜
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2017.10.23
require "http"
require "gps"
module(..., package.seeall)
-- 星历数据本地文件名
local AlmanacData = "/AlmanacData.dat"
-- 下载星历返回状态码,headers,body内容
local code, head, data
--- 下载星历数据
function setup(timeout, upTime)
    sys.taskInit(function(timeout, upTime)
        local len = 0
        while true do
            while not socket.isReady() do sys.wait(1000) end
            code, head, data = http.request("GET", "download.openluat.com/9501-xingli/brdcGPD.dat_rda", timeout)
            if code == "200" then
                data, len = data:fromhex()
                gps.open()
                sys.wait(2000)
                gps.update(data)
                io.writefile(AlmanacData, data)
                log.info("agps.gpd length:", len)
            end
            sys.wait(upTime)
        end
    end, timeout, upTime)
end
--- 获取星历数据
function getAlmanacData()
    return data or io.readfile(AlmanacData)
end
