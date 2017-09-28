--- 数据链路激活(创建、连接、状态维护)
-- @module link
-- @author 稀饭放姜、小强
-- @license MIT
-- @copyright openLuat.com
-- @release 2017.9.20
local sys = require "sys"
local ril = require "ril"
local log = require "log"
module(..., package.seeall)
local publish = sys.publish
local request = ril.request


-- apn，用户名，密码
local apnname = "CMNET"
local username = ''
local password = ''

-- apnflg：本功能模块是否自动获取apn信息，true是，false则由用户应用脚本自己调用setapn接口设置apn、用户名和密码
local apnFlag = true

--- 设置APN的参数
-- @string apn, APN的名字
-- @string user, APN登陆用户名
-- @string pwd,  APN登陆用户密码
function setApn(apn, user, pwd)
    apnname, username, password = apn, user or '', pwd or ''
    apnflag = false
end

--- 获取APN的名称
-- @return string, APN的名字
function getApn()
    return apnname
end

-- SIM卡 IMSI READY以后自动设置APN
sys.subscribe("IMSI_READY", function()
    if apnflag then
        if apn then
            local temp1, temp2, temp3 = apn.get_default_apn(tonumber(sim.getMcc(), 16), tonumber(sim.getMnc(), 16))
            if temp1 == '' or temp1 == nil then temp1 = "CMNET" end
            setApn(temp1, temp2, temp3)
        else
            --sim卡的默认apn表
            local apntable = {
                ["46000"] = "CMNET",
                ["46002"] = "CMNET",
                ["46004"] = "CMNET",
                ["46007"] = "CMNET",
                ["46001"] = "UNINET",
                ["46006"] = "UNINET",
            }
            setApn(apntable[sim.getMcc() .. sim.getMnc()] or "CMNET")
        end
    end
end)

local function ipState(data, prefix)
    status = string.sub(data, 8, -1)
    if status == "IP GPRSACT" then
        request("AT+CIFSR")
        request("AT+CIPSTATUS")
    elseif status == "IP PROCESSING" or status == "IP STATUS" then
        sys.timer_stop(request, 2000, "AT+CIPSTATUS")
        publish("IP_STATUS_SUCCESS")
    elseif status == "IP INITIAL" or status == "PDP DEACT" then
        request("AT+CSTT=\"" .. apnname .. '\",\"' .. username .. '\",\"' .. password .. "\"")
        request("AT+CIICR")
    elseif status == "IP CONFIG" or status == "IP START" then
        sys.timer_start(request, 2000, "AT+CIPSTATUS")
    end
    ipStatus = status
    log.info("link.ipState", "IP STATUS is:", ipStatus)
end

ril.regurc("STATE", ipState)
ril.regurc("+PDP", function()request("AT+CIPSTATUS") end)

-- initial 只能初始化1次，这里是初始化完成标志位
local inited = false

local function initial()
    if not inited then
        inited = true
        request("AT+CIICRMODE=2")--ciicr异步
        request("AT+CIPMUX=1")--多链接
        request("AT+CIPHEAD=1")
        request("AT+CIPQSEND=0")--发送模式
    end
end

-- GPRS附着成功 开始IP状态机处理
local function cgattRsp(cmd, success, response, intermediate)
    --已附着
    if intermediate == "+CGATT: 1" then
        request("AT+CIPSTATUS")
    else
        sys.timer_start(request, 2000, "AT+CGATT?", nil, cgattRsp)
    end
end

-- 网络注册成功 发起GPRS附着状态查询
sys.subscribe("NET_STATE_REGISTERED", function()
    initial()
    sys.timer_start(request, 2000, "AT+CGATT?", nil, cgattRsp)
end)
