--- 模块功能：星历更新服务
-- @module agps
-- @author 稀饭放姜
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2017.10.23
require "http"
module(..., package.seeall)
-- 星历数据本地文件名
local GPD_FILE = "/GPD.txt"

--- 下载星历数据
-- @number timeout,下载星历超时等待时间
-- @return string,星历数据的HEX字符串
-- @usage agps.refresh(30000)
function refresh(timeout)
    while not socket.isReady() do sys.wait(1000) end
    local code, head, data = http.request("GET", "download.openluat.com/9501-xingli/brdcGPD.dat_rda", timeout)
    if code == "200" then
        local data, len = data:tohex()
        log.info("agps.gpd length,file:", len, io.writefile(GPD_FILE, data))
        return data
    end
end
--- 获取星历数据
-- @return string,星历数据的HEX字符串
-- @usage agps.getGPD()
function getGPD()
    return io.readfile(GPD_FILE) or refresh(30000)
end
