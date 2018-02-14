--- 模块功能：网络授时
-- @module ntp
-- @author 稀饭放姜
-- @license MIT
-- @copyright openLuat
-- @release 2017.10.21
require "misc"
require "socket"
require "utils"
require "log"
local sbyte, ssub = string.byte, string.sub
module(..., package.seeall)
-- NTP服务器域名集合
local timeServer = {
    "ntp1.aliyun.com",
    "ntp2.aliyun.com",
    "ntp3.aliyun.com",
    "ntp4.aliyun.com",
    "ntp5.aliyun.com",
    "ntp7.aliyun.com",
    "ntp6.aliyun.com",
    "s2c.time.edu.cn",
    "194.109.22.18",
    "210.72.145.44",
}
-- 同步超时等待时间
local NTP_TIMEOUT = 8000
-- 同步重试次数
local NTP_RETRY = 3
-- 同步是否完成标记
local ntpend = false
function isEnd()
    return ntpend
end

--- 同步时间，每个NTP服务器尝试3次，超时8秒,适用于被任务函数调用
-- @param ts,每隔ts小时同步1次
-- @param fnc,同步成功后回调函数
-- @return 无
-- @usage ntp.ntpTime() -- 只同步1次
-- @usage ntp.ntpTime(1) -- 1小时同步1次
-- @usage ntp.ntpTime(nil,fnc) -- 只同步1次，同步成功后执行fnc()
-- @usage ntp.ntpTime(24,fnc) -- 24小时同步1次，同步成功后执行fnc()
function ntpTime(ts,fnc)
    local rc, data, ntim
    ntpend = false
    while true do
        for i = 1, #timeServer do
            while not socket.isReady() do sys.wait(1000) end
            local c = socket.udp()
            for num = 1, NTP_RETRY do
                if c:connect(timeServer[i], "123") then                
                    if c:send(string.fromhex("E30006EC0000000000000000314E31340000000000000000000000000000000000000000000000000000000000000000")) then
                        rc, data = c:recv(NTP_TIMEOUT)
                        if rc and #data == 48 then
                            ntim = os.date("*t", (sbyte(ssub(data, 41, 41)) - 0x83) * 2 ^ 24 + (sbyte(ssub(data, 42, 42)) - 0xAA) * 2 ^ 16 + (sbyte(ssub(data, 43, 43)) - 0x7E) * 2 ^ 8 + (sbyte(ssub(data, 44, 44)) - 0x80) + 1)
                            misc.setClock(ntim)
                            ntpend = true 
                            if fnc ~= nil and type(fnc) == "function" then fnc() end
                            break
                        end
                    end 
                end
                sys.wait(1000)
            end          
            c:close() 
        end
        if ntpend then 
            log.info("ntp.timeSync is date:", ntim.year .. "/" .. ntim.month .. "/" .. ntim.day .. "," .. ntim.hour .. ":" .. ntim.min .. ":" .. ntim.sec) 
            if ts == nil or type(ts) ~= "number" then break end
            sys.wait(ts * 3600 * 1000)
        else
            log.info("ntp.timeSync is error!")
            sys.wait(1000)
        end
    end
end
---  自动同步时间任务适合独立执行
-- @return 无
-- @param ts,每隔ts小时同步1次
-- @param fnc,同步成功后回调函数
-- @usage ntp.timeSync() -- 只同步1次
-- @usage ntp.timeSync(1) -- 1小时同步1次
-- @usage ntp.timeSync(nil,fnc) -- 只同步1次，同步成功后执行fnc()
-- @usage ntp.timeSync(24,fnc) -- 24小时同步1次，同步成功后执行fnc()
function timeSync(ts,fnc)
    sys.taskInit(ntpTime,ts,fnc)
end

