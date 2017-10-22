--- 模块功能：LED闪灯模块
-- @module led
-- @author smset,稀饭放姜
-- @license MIT
-- @copyright openLuat
-- @release 2017.09.23 11:34
module(..., package.seeall)

local pins = require "pins"
local sys = require "sys"
require "patch"
local base = _G
-- 加载常用的全局函数至本地
local unpack = base.unpack
local ipairs = base.ipairs
local type = base.type
local pairs = base.pairs
local assert = base.assert
local tonumber = base.tonumber

-- 默认net灯的GPIO
local LED_PIN = pio.P0_28
-- 默认灯亮的事件
local lighting = true
-- batt:电量指示任务，net:网络指示任务,breate:呼吸灯
local staLed = "net"

--[[
-- 电量任务切换
-- 值为1时标识电量25%
-- 值为2时标识电量50%
-- 值为3时标识电量75%
-- 值为4时标识电量100%
]]
local blinkCount = 4

-- netLink 链接状态
-- netLinkSta = "flymode"  -- 飞行模式
-- netLinkSta = "sign"     -- 注册
-- netLinkSta == "hold"    -- 保持
-- netLinkSta == "active"  -- 活动
local netLinkSta = "FLYMODE"

-- 电量指示灯亮、灭、周期参数单位ms
local blinkLight, blinkDark, blinkDull = 200, 300, 3000

-- 呼吸灯的状态、PWM周期
local bLighting, bDarking, LED_PWM = false, true, 18

--- 设置指示灯功能开关
-- @bool sta，true or false
-- @return 无
-- @usage led.setStaLed("batt")
function setLighting(sta)
    lighting = sta or lighting
end

--- 设置指示灯显示功能
-- @string str，"net","batt","breate"
-- @return 无
-- @usage led.setStaLed("batt")
function setStaLed(str)
    staLed = str or staLed
end

--- 自定义电量闪烁状态
-- @number light ,指示灯亮的时间ms
-- @number dark ，指示灯灭的时间ms
-- @number dull ，两次指示间隔的时间ms
-- @return 无
-- @usage setBattBlink(300,700,3000)
function setBattBlink(light, dark, dull)
    blinkLight = light or blinkLight
    blinkDark = dark or blinkDark
    blinkDull = dull or blinkDull
end

--- 设置网络指示灯状态
-- @string str，"sleep","sign","hold","active"
-- @return 无
-- @usage led.setNetLinkSta("hold")
function setNetLinkSta(str)
    netLinkSta = str or netLinkSta
end
--- 设置电量指示灯状态
-- @number lev，1-4,标识电量25%-100%
-- @return 无
-- @usage led.setBattLevel("hold")
function setBattLevel(lev)
    blinkCount = lev or blinkCount
end
--[[
-- 功能：按照给定的亮暗时间产生闪灯效果
-- 参数:ledPIN-灯的引脚，light-亮灯时间ms，dark-灭灯时间ms
-- 返回：无
--]]
local function blinkPwm(ledPin, light, dark)
    ledPin(1)
    sys.wait(light)
    ledPin(0)
    sys.wait(dark)
end
--[[
-- 模块功能：网络指示灯任务切换
-- 返回值：无
]]
local function netLink(ledPin)
    if netLinkSta == "FLYMODE" then
        ledPin(0)
    elseif netLinkSta == "NET_STATE_REGISTERED" then
        blinkPwm(ledPin, 500, 500)
    elseif netLinkSta == "IP_STATUS_SUCCESS" then
        blinkPwm(ledPin, 100, 1900)
    elseif netLinkSta == "SOCKET_ACTIVE" then
        blinkPwm(ledPin, 100, 100)
    end
end
--[[
-- 电池电量显示
-- @参数：电量指示灯的GPIO
-- @return 无
--]]
local function battLevel(ledPin)
    for i = 1, blinkCount do blinkPwm(ledPin, blinkLight, blinkDark, blinkDull) end
    sys.wait(blinkDull)
end
--[[
-- 呼吸灯显示
-- @参数：呼吸灯的GPIO
-- @return 无
--]]
local function breateLed(ledPin)
    if bLighting then
        for i = 1, LED_PWM - 1 do
            ledPin(0)
            sys.wait(i)
            ledPin(1)
            sys.wait(LED_PWM - i)
        end
        bLighting = false
        bDarking = true
        ledPin(0)
        sys.wait(700)
    end
    if bDarking then
        for i = 1, LED_PWM - 1 do
            ledPin(0)
            sys.wait(LED_PWM - i)
            ledPin(1)
            sys.wait(i)
        end
        bLighting = true
        bDarking = false
        ledPin(1)
        sys.wait(700)
    end
end
--[[
-- 模块功能：LED模块的运行任务
-- 参数：指示灯的GPIO
-- @返回值 无
--]]
local function taskLed(ledPin)
    while true do
        if lighting then
            if staLed == "net" then
                netLink(ledPin)
            elseif staLed == "batt" then
                battLevel(ledPin)
            elseif staLed == "breate" then
                breateLed(ledPin)
            end
        end
        sys.wait(100)
    end
end
--- 配置指示灯的GPIO
-- @param ledPin , 模块闪灯GPIO引脚
-- @return 无
-- @usage setup(pio.P0_28)
function setup(ledPin)
    sys.taskInit(taskLed, pins.setup(ledPin or LED_PIN, 0))
end
sys.subscribe("NET_STATE_REGISTERED", function()netLinkSta = "NET_STATE_REGISTERED" end)
sys.subscribe("IP_STATUS_SUCCESS", function()netLinkSta = "IP_STATUS_SUCCESS" end)
sys.subscribe("SOCKET_ACTIVE", function()netLinkSta = "SOCKET_ACTIVE" end)
sys.subscribe("NET_STATE_UNREGISTER", function()netLinkSta = "FLYMODE" end)
sys.subscribe("FLYMODE", function()netLinkSta = "FLYMODE" end)
