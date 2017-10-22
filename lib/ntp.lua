--- 模块功能：网络授时
-- @module ntp
-- @author 稀饭放姜
-- @license MIT
-- @copyright openLuat
-- @release 2017.10.21
require "common"
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
-- 网络获取的时间table
local ntpTime = {}
function timeSync()
    sys.taskInit(function()
        sys.waitUntil("IP_STATUS_SUCCESS", 60000)
        local num = 0
        for i = 1, #timeServer do
            local c = socket.udp()
            while true do
                -- while not c:connect(timeServer[i], "123") do
                --     num = num + 1
                --     sys.wait(NTP_TIMEOUT)
                --     if num == NTP_RETRY then break end
                -- end
                for num = 1, NTP_RETRY do if c:connect(timeServer[i], "123") then break end sys.wait(NTP_TIMEOUT) end
                if not c:send(common.hexstobins("E30006EC0000000000000000314E31340000000000000000000000000000000000000000000000000000000000000000")) then break end
                local _, data = c:recv()
                if #data ~= 48 then break end
                ntpTime = os.date("*t", (sbyte(ssub(data, 41, 41)) - 0x83) * 2 ^ 24 + (sbyte(ssub(data, 42, 42)) - 0xAA) * 2 ^ 16 + (sbyte(ssub(data, 43, 43)) - 0x7E) * 2 ^ 8 + (sbyte(ssub(data, 44, 44)) - 0x80) + 1)
                misc.setClock(ntpTime)
                break
            end
            c:close()
            sys.wait(1000)
            local date = misc.getClock()
            log.info("ntp.timeSync is date:\t", date.year .. "/" .. date.month .. "/" .. date.day .. "," .. date.hour .. ":" .. date.min .. ":" .. date.sec)
            if ntpTime.year == date.year and ntpTime.day == date.day and ntpTime.min == date.min then ntpTime = {} break end
        end
    end)
end
