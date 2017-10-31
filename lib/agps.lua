--- 模块功能：星历更新服务
-- @module agps
-- @author 稀饭放姜
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2017.10.23
require "http"
require "net"
module(..., package.seeall)
-- 星历数据本地文件名
local GPD_FILE = "/GPD.txt"
local LBS_FILE = "/LBS.txt"

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


--- 下载基站坐标
-- @number timeout，下载基站信息超时等待时间
-- @return string,基站坐标字符串,基站没准备好返回nil
-- @usage agps.cellTrack()
function cellTrack()
    local ct, info = {}
    while not socket.isReady() do sys.wait(1000) end
    info = net.getCellInfoExt()
    if info == "" then return end
    for mcc, mnc, lac, ci, rssi in info:gmatch("(%d+)%.(%d+)%.(%d+)%.(%d+)%.(%d+);") do
        local tmp = {}
        tmp.mcc = tonumber(mcc)
        tmp.mnc = tonumber(mnc)
        tmp.lac = tonumber(lac)
        tmp.ci = tonumber(ci)
        tmp.hex = "10"
        tmp.rssi = (tonumber(rssi) > 31) and 31 or tonumber(rssi)
        table.insert(ct, tmp)
    end
    ct = json.encode(ct)
    -- 发送请求报文
    local code, head, data = http.request("GET", "api.openluat.com", timeout)
    if code == "200" then
        local data, len = data:tohex()
        log.info("agps.gpd length,file:", len, io.writefile(LBS_FILE, data))
        return data
    end
end
--- 获取基站坐标
-- @return string,基站定位的坐标字符串
-- @usage agps.getLBS()
function getLBS()
    return io.readfile(LBS_FILE) or cellTrack()
end
