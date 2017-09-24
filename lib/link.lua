--- 数据链路激活、SOCKET管理(创建、连接、数据收发、状态维护)
-- @module link
-- @author 稀饭放姜、小强
-- @license MIT
-- @copyright openLuat.com
-- @release 2017.9.20
module(..., package.seeall)
-- 定义模块,导入依赖库
local base = _G
local string = require "string"
local table = require "table"
local sys = require "sys"
local ril = require "ril"
local net = require "net"
local rtos = require "rtos"
local sim = require "sim"
-- 加载常用的全局函数至本地
local print = base.print
local pairs = base.pairs
local tonumber = base.tonumber
local tostring = base.tostring
local wait = sys.wait
local waitUntil = sys.waitUntil
local publish = sys.publish
local request = ril.request

-- 最大socket id，从0开始，所以同时支持的socket连接数是8个
local MAXLINKS = 7
--IP环境建立失败时间隔5秒重连
local IPSTART_INTVL = 5000

-- socket连接表
local linkList = {}
-- ipStatus：IP环境状态
-- shuting：是否正在关闭数据网络
local ipStatus, shuting = "IP INITIAL"
-- GPRS数据网络附着状态，"1"附着，其余未附着
-- local cgatt
-- apn，用户名，密码
local apnname = "CMNET"
local username = ''
local password = ''
-- socket发起连接请求后，响应间隔超时策略："restart" or "reconn"
local reconnStrategy = "reconn"
-- socket发起连接请求后，响应间隔ms
local reconnInterval
-- apnflg：本功能模块是否自动获取apn信息，true是，false则由用户应用脚本自己调用setapn接口设置apn、用户名和密码
-- checkciicrtm, 执行AT+CIICR后，如果设置了checkciicrtm，checkciicrtm毫秒后，没有激活成功，则重启软件（中途执行AT+CIPSHUT则不再重启）
-- ciicrerrcb,用户自定义AT+CIIR激活超时自定义回调函数
-- flyMode：是否处于飞行模式
-- updating：是否正在执行远程升级功能(update.lua)
-- dbging：是否正在执行dbg功能(dbg.lua)
-- ntping：是否正在执行NTP时间同步功能(ntp.lua)
-- shutpending：是否有等待处理的进入AT+CIPSHUT请求
local apnFlag, flyMode, updating, dbging, ntping, shutpending = true

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

--[[
函数名：cgattrsp
功能  ：查询GPRS数据网络附着状态的应答处理
参数  ：
cmd：此应答对应的AT命令
success：AT命令执行结果，true或者false
response：AT命令的应答中的执行结果字符串
intermediate：AT命令的应答中的中间信息
返回值：无
]]
local function cgattRsp(cmd, success, response, intermediate)
    --已附着
    if intermediate == "+CGATT: 1" then
        -- 发布GPRS附着消息
        publish("NET_GPRS_READY")
        -- 如果存在链接,那么在gprs附着上以后自动激活IP网络
        if base.next(linkList) then
            if ipStatus == "IP INITIAL" then
                -- 激活IP服务
                request("AT+CSTT=\"" .. apnname .. '\",\"' .. username .. '\",\"' .. password .. "\"")
                request("AT+CIICR")
            end
            --查询激活状态
            request("AT+CIPSTATUS")
            print("link.cgattRsp is NET_GPRS_READY:\t", intermediate)
        end
    --发布GPRS分离消息
    elseif intermediate == "+CGATT: 0" then
        publish("CONNECTION_LINK_ERROR")
        print("link.cgattRsp is NET_GPRS_NOTREADY:\t", intermediate)
    end
end

--[[
函数名：ipState
功能  ：IP网络状态处理函数
参数  ：
data：IP网络状态
prefix: +CIPSTATUS 的返回主动上报urc 前缀STATE
返回值：无
]]
local function ipState(data, prefix)
    status = string.sub(data, 8, -1)
    if status == "IP GPRSACT" then
        --获取IP地址，地址获取成功后，IP网络状态会切换为"IP STATUS"
        request("AT+CIFSR")
        -- 查询连接状态，是否正确获取IP地址
        request("AT+CIPSTATUS")
        -- 发布 PDP成功消息
        publish("IP_PDP_READY")
    elseif status == "IP PROCESSING" or status == "IP STATUS" then
        -- 发布IP服务激活成功消息
        publish("IP_STATUS_SUCCESS")
    elseif status == "PDP DEACT" then
        if ipStatus == "IP PROCESSING" or ipStatus == "IP STATUS" or ipStatus == "IP GPRSACT" then
            -- IP服务激活过程中发生的‘PDP DEACT' 处理
            else
            publish("CONNECTION_LINK_ERROR")
        end
    end
    ipStatus = status
    print("link.ipState IP STATUS is :\t", ipStatus)
end

--sim卡的默认apn表
local apntable = {
    ["46000"] = "CMNET",
    ["46002"] = "CMNET",
    ["46004"] = "CMNET",
    ["46007"] = "CMNET",
    ["46001"] = "UNINET",
    ["46006"] = "UNINET",
}

--[[
IMSI读取成功的回调函数
函数功能：自动设置APN的参数
--]]
local function getApn(id, para)
    --本模块内部自动获取apn信息进行配置
    if apnflag then
        if apn then
            local temp1, temp2, temp3 = apn.get_default_apn(tonumber(sim.getMcc(), 16), tonumber(sim.getMnc(), 16))
            if temp1 == '' or temp1 == nil then temp1 = "CMNET" end
            setApn(temp1, temp2, temp3)
        else
            setApn(apntable[sim.getMcc() .. sim.getMnc()] or "CMNET")
        end
    end
end
--[[
函数名：proc
功能  ：本模块注册的内部消息的处理函数
参数  ：
id：内部消息id
para：内部消息参数
返回值：true
]]
---[[
local function proc(id, para)
    
    --飞行模式状态变化
    if id == "FLYMODE_IND" then
        flymode = para
        if para then
            sys.timer_stop(request, "AT+CIPSTATUS")
        else
            request("AT+CGATT?", nil, cgattRsp)
        end
    --远程升级开始
    elseif id == "UPDATE_BEGIN_IND" then
        updating = true
    --远程升级结束
    elseif id == "UPDATE_END_IND" then
        updating = false
        if shutpending then shut() end
    --dbg功能开始
    elseif id == "DBG_BEGIN_IND" then
        dbging = true
    --dbg功能结束
    elseif id == "DBG_END_IND" then
        dbging = false
        if shutpending then shut() end
    --NTP同步开始
    elseif id == "NTP_BEGIN_IND" then
        ntping = true
    --NTP同步结束
    elseif id == "NTP_END_IND" then
        ntping = false
        if shutpending then shut() end
    end
    return true
end
--]]
--[[
函数名：rsp
功能  ：本功能模块内“通过虚拟串口发送到底层core软件的AT命令”的应答处理
参数  ：
cmd：此应答对应的AT命令
success：AT命令执行结果，true或者false
response：AT命令的应答中的执行结果字符串
intermediate：AT命令的应答中的中间信息
返回值：无
]]
---[[
local function rsp(cmd, success, response, intermediate)
    local prefix = string.match(cmd, "AT(%+%u+)")
    local id = tonumber(string.match(cmd, "AT%+%u+=(%d)"))
    --发送数据到服务器的应答
    if prefix == "+CIPSEND" then
        if response == "+PDP: DEACT" then
            request("AT+CIPSTATUS")
            response = "ERROR"
        end
        if string.match(response, "DATA ACCEPT") then
            sendcnf(id, "SEND OK")
        else
            sendcnf(id, getresult(response))
        end
    --关闭socket的应答
    elseif prefix == "+CIPCLOSE" then
        closecnf(id, getresult(response))
    --关闭IP网络的应答
    elseif prefix == "+CIPSHUT" then
        shutcnf(response)
    --连接到服务器的应答
    elseif prefix == "+CIPSTART" then
        if response == "ERROR" then
            publish("CONNECT_CREATE_FAILED")
        end
    --激活IP网络的应答
    elseif prefix == "+CIICR" then
        if success then
            ipStatus = "IP CONFIG"
        else
            publish("CONNECTION_LINK_ERROR")
        end
    end
end
--]]
--[[
函数名：urc
功能  ：本功能模块内“注册的底层core通过虚拟串口主动上报的通知”的处理
参数  ：
data：通知的完整字符串信息
prefix：通知的前缀
返回值：无
]]
---[[
function urc(data, prefix)
    
    if prefix == "C" then
        
        --linkstatus(data)
        --IP网络被动的去激活
        elseif prefix == "+PDP" then --request("AT+CIPSTATUS")
        shut()
        sys.timer_stop(request, "AT+CIPSTATUS")
        --socket收到服务器发过来的数据
        elseif prefix == "+RECEIVE" then
            local lid, len = string.match(data, ",(%d),(%d+)", string.len("+RECEIVE") + 1)
            rcvd.id = tonumber(lid)
            rcvd.len = tonumber(len)
            return rcvdfilter
        --socket状态通知
        else
            local lid, lstate = string.match(data, "(%d), *([%u :%d]+)")
            if lid then
                lid = tonumber(lid)
                statusind(lid, lstate)
            end
    end
end
--]]
--注册以下urc通知的处理函数
ril.regurc("STATE", ipState)
ril.regurc("C", urc)
ril.regurc("+PDP", urc)
ril.regurc("+RECEIVE", urc)
-- 订阅AT命令返回消息
ril.regrsp("+CIPSTART", rsp)-- 订阅“建立TCP/UDP连接”返回消息
ril.regrsp("+CIPSEND", rsp)-- 订阅“发送数据”返回消息
ril.regrsp("+CIPCLOSE", rsp)-- 订阅“关闭TCP/UDP连接”返回消息
ril.regrsp("+CIPSHUT", rsp)-- 订阅“关闭移动场景”返回消息
-- ril.regrsp("+CIICR", rsp)-- 订阅“激活移动场景”返回消息
-- 订阅app消息
sys.subscribe(getApn, "IMSI_READY")
sys.subscribe(proc, "FLYMODE_IND", "UPDATE_BEGIN_IND", "UPDATE_END_IND", "DBG_BEGIN_IND", "DBG_END_IND", "NTP_BEGIN_IND", "NTP_END_IND")


-- initial 只能初始化1次，这里是初始化完成标志位
local inited = false
-- 配置发送模式 0是慢发，1是快发，默认慢发模式返回SEND OK
local qsend = 0
--[[
函数名：initial
功能  ：配置本模块功能的一些初始化参数
参数  ：无
返回值：无
]]
local function initial()
    if not inited then
        inited = true
        request("AT+CIICRMODE=2")--ciicr异步
        request("AT+CIPMUX=1")--多链接
        request("AT+CIPHEAD=1")
        request("AT+CIPQSEND=" .. qsend)--发送模式
    end
end

function SetQuickSend(mode)
    qsend = mode
end

--[[
函数名：validaction
功能  ：检查某个socket id的动作是否有效
参数  ：
id：socket id
action：动作
返回值：true有效，false无效
]]
local function validaction(id, action)
    --socket无效
    if linkList[id] == nil then
        print("link.validaction:id nil", id)
        return false
    end
    
    --同一个状态不重复执行
    if action .. "ING" == linkList[id].state then
        print("link.validaction:", action, linkList[id].state)
        return false
    end
    
    local ing = string.match(linkList[id].state, "(ING)", -3)
    
    if ing then
        --有其他任务在处理时,不允许处理连接,断链或者关闭是可以的
        if action == "CONNECT" then
            print("link.validaction: action running", linkList[id].state, action)
            return false
        end
    end
    
    -- 无其他任务在执行,允许执行
    return true
end

--- socket连接服务器请求
-- @number id,socket id
-- @string protocol,传输层协议TCP或者UDP
-- @string address,服务器地址
-- @number port,服务器端口
-- @return bool,请求成功同步返回true，否则false；
function connect(id, protocol, address, port)
    --不允许发起连接动作
    if validaction(id, "CONNECT") == false or linkList[id].state == "CONNECTED" then
        return false
    end
    print("link.connect: ", id, protocol, address, port, ipstatus, shuting, shutpending)
    
    linkList[id].state = "CONNECTING"
    
    if cc and cc.anycallexist() then
        --如果打开了通话功能 并且当前正在通话中使用异步通知连接失败
        print("link.connect:failed cause call exist")
        publish("LINK_ASYNC_LOCAL_EVENT", statusind, id, "CONNECT FAIL")
        return false
    end
    
    local connstr = string.format("AT+CIPSTART=%d,\"%s\",\"%s\",%s", id, protocol, address, port)
    
    if (ipstatus ~= "IP STATUS" and ipstatus ~= "IP PROCESSING") or shuting or shutpending then
        --ip环境未准备好先加入等待
        linkList[id].pending = connstr
    else
        --发送AT命令连接服务器
        request(connstr)
    end
    return true
end

--- GPRS网络IP服务连接处理任务
function connectionTask()
    while true do
        -- 等待GSM注册成功
        while not waitUntil("NET_STATE_REGISTERED", 120000) do end
        -- 初始化PDP注册之前的一些参数
        initial()
        -- 每隔2000ms查询1次GPRS附着状态，直到附着成功。
        while not waitUntil("NET_GPRS_READY", 2000, function()request("AT+CGATT?", nil, cgattRsp) end) do end
        -- 每隔2000ms查询1次 PDP_READY 消息
        while not waitUntil("IP_PDP_READY", 2000, function()request("AT+CIPSTATUS") end) do end
        -- 激活IP服务，等待IP获取成功消息,每隔2秒查询1次
        while not waitUntil("IP_STATUS_SUCCESS", 2000, function()request("AT+CIPSTATUS") end) do end
        -- while not waitUntil("LINK_STATE_INVALID", 120000) do end
        while not waitUntil("CONNECTION_LINK_ERROR", 12000) do end
    end
end
