--- 模块功能：luat协程调度框架
-- @module sys
-- @author 稀饭放姜 小强
-- @license MIT
-- @copyright openLuat.com
-- @release 2017.9.13
require "patch"
require "errdump"
module(..., package.seeall)

-- lib脚本版本号，只要lib中的任何一个脚本做了修改，都需要更新此版本号
SCRIPT_LIB_VER = "2.0.0"
-- 脚本发布时的最新core软件版本号
CORE_MIN_VER = "Luat_V0010_8955"

-- TaskID最大值
local TASK_TIMER_ID_MAX = 0x1FFFFFFF
-- msgId 最大值(请勿修改否则会发生msgId碰撞的危险)
local MSG_TIMER_ID_MAX = 0x7FFFFFFF

-- 任务定时器id
local taskTimerId = 0
-- 消息定时器id
local msgId = TASK_TIMER_ID_MAX
-- 定时器id表
local timerPool = {}
local taskTimerPool = {}
--消息定时器参数表
local para = {}


--- 启动GSM协议栈。例如在充电开机未启动GSM协议栈状态下，如果用户长按键正常开机，此时调用此接口启动GSM协议栈即可
-- @return 无
-- @usage sys.powerOn()
function powerOn()
    rtos.poweron(1)
end

--- 软件重启
-- @string r 重启原因，用户自定义，一般是string类型，重启后的trace中会打印出此重启原因
-- @return 无
-- @usage sys.restart('程序超时软件重启')
function restart(r)
    assert(r and r ~= "", "sys.restart cause null")
    errdump.appendErr("restart[" .. r .. "];")
    rtos.restart()
end

--- Task任务延时函数，只能用于任务函数中
-- @number ms  整数，最大等待126322567毫秒
-- @return number 正常返回1，失败返回nil
-- @usage sys.wait(30)
function wait(ms)
    -- 参数检测，参数不能为负值
    assert(ms > 0, "The wait time cannot be negative!")
    -- 选一个未使用的定时器ID给该任务线程
    while true do
        -- 防止taskId超过30
        if taskTimerId >= TASK_TIMER_ID_MAX then taskTimerId = 0 end
        taskTimerId = taskTimerId + 1
        taskTimerPool[coroutine.running()] = taskTimerId
        timerPool[taskTimerId] = coroutine.running()
        break
    end
    -- 调用core的rtos定时器
    if 1 ~= rtos.timer_start(taskTimerId, ms) then print("rtos.timer_start error") return end
    -- 挂起调用的任务线程
    local message, data = coroutine.yield()
    if message then
        rtos.timer_stop(taskTimerId)
        taskTimerPool[coroutine.running()] = nil
        timerPool[taskTimerId] = nil
        return message, data
    end
end

--- Task任务的条件等待函数（包括事件消息和定时器消息等条件），只能用于任务函数中。
-- @param id 消息ID
-- @number ms 等待超时时间，单位ms，最大等待126322567毫秒
-- @return result 接收到消息返回true，超时返回false
-- @return data 接收到消息返回消息参数
-- @usage result, data = sys.waitUntil("SIM_IND", 120000)
-- @usage if result then print("received message", data) end
-- @usage elseif print("timeout") end
function waitUntil(id, ms)
    subscribe(id, coroutine.running())
    local message, data = wait(ms)
    unsubscribe(id, coroutine.running())
    return message ~= nil, data
end

--- 创建一个任务线程,在模块最末行调用该函数并注册模块中的任务函数，main.lua导入该模块即可
-- @param fun 任务函数名，用于resume唤醒时调用
-- @param ... 任务函数fun的可变参数
-- @return co  返回该任务的线程号
-- @usage sys.taskInit(task1,'a','b')
function taskInit(fun, ...)
    co = coroutine.create(fun)
    coroutine.resume(co, unpack(arg))
    return co
end

--[[
检查底层软件版本号和lib脚本需要的最小底层软件版本号是否匹配
]]
local function checkCoreVer()
    local realver = rtos.get_version()
    --如果没有获取到底层软件版本号
    if not realver or realver == "" then
        appendErr("checkCoreVer[no core ver error];")
        return
    end
    
    local buildver = string.match(realver, "Luat_V(%d+)_")
    --如果底层软件版本号格式错误
    if not buildver then
        appendErr("checkCoreVer[core ver format error]" .. realver .. ";")
        return
    end
    
    --lib脚本需要的底层软件版本号大于底层软件的实际版本号
    if tonumber(string.match(CORE_MIN_VER, "Luat_V(%d+)_")) > tonumber(buildver) then
        print("checkCoreVer[core ver match warn]" .. realver .. "," .. CORE_MIN_VER .. ";")
    end
end

--- Luat平台初始化
-- @param mode 充电开机是否启动GSM协议栈，1不启动，否则启动
-- @param lprfnc 用户应用脚本中定义的“低电关机处理函数”，如果有函数名，则低电时，本文件中的run接口不会执行任何动作，否则，会延时1分钟自动关机
-- @return 无
-- @usage sys.init(1,0)
function init(mode, lprfnc)
    -- 用户应用脚本中必须定义PROJECT和VERSION两个全局变量，否则会死机重启，如何定义请参考各个demo中的main.lua
    assert(PROJECT and PROJECT ~= "" and VERSION and VERSION ~= "", "Undefine PROJECT or VERSION")
    collectgarbage("setpause", 80)
    
    -- 设置AT命令的虚拟串口
    uart.setup(uart.ATC, 0, 0, uart.PAR_NONE, uart.STOP_1)
    print("poweron reason:", rtos.poweron_reason(), PROJECT, VERSION, SCRIPT_LIB_VER, rtos.get_version())
    if mode == 1 then
        -- 充电开机
        if rtos.poweron_reason() == rtos.POWERON_CHARGER then
            -- 关闭GSM协议栈
            rtos.poweron(0)
        end
    end
    -- 如果存在脚本运行错误文件，打开文件，打印错误信息
    local f = io.open("/luaerrinfo.txt", "r")
    if f then
        print(f:read("*a") or "")
        f:close()
    end
    -- 打印LIB_ERR_FILE文件中的错误信息
    errdump.initErr()
    checkCoreVer()
end

------------------------------------------ rtos消息回调处理部分 ------------------------------------------
--[[
函数名：cmpTable
功能  ：比较两个table的内容是否相同，注意：table中不能再包含table
参数  ：
t1：第一个table
t2：第二个table
返回值：相同返回true，否则false
]]
local function cmpTable(t1, t2)
    if not t2 then return #t1 == 0 end
    if #t1 == #t2 then
        for i = 1, #t1 do
            if unpack(t1, i, i) ~= unpack(t2, i, i) then
                return false
            end
        end
        return true
    end
    return false
end

--- 关闭定时器
-- @param val 值为number时，识别为定时器ID，值为回调函数时，需要传参数
-- @param ... val值为函数时，函数的可变参数
-- @return 无
-- @usage timer_stop(1)
function timer_stop(val, ...)
    -- val 为定时器ID
    if type(val) == 'number' then
        timerPool[val], para[val] = nil
        rtos.timer_stop(val)
    else
        for k, v in pairs(timerPool) do
            -- 回调函数相同
            if type(v) == 'table' and v.cb == val or v == val then
                -- 可变参数相同
                if cmpTable(arg, para[k]) then
                    rtos.timer_stop(k)
                    timerPool[k], para[k] = nil
                    break
                end
            end
        end
    end
end

--- 函数功能--开启一个定时器
-- @param fnc 定时器回调函数
-- @number ms 整数，最大定时126322567毫秒
-- @param ... 可变参数 fnc的参数
-- @return number 定时器ID，如果失败，返回nil
function timer_start(fnc, ms, ...)
    --回调函数和时长检测
    assert(fnc ~= nil, "sys.timer_start(first param) is nil !")
    assert(ms > 0, "sys.timer_start(Second parameter) is <= zero !")
    -- 关闭完全相同的定时器
    if arg.n == 0 then
        timer_stop(fnc)
    else
        timer_stop(fnc, unpack(arg))
    end
    -- 为定时器申请ID，ID值 1-20 留给任务，20-30留给消息专用定时器
    while true do
        if msgId >= MSG_TIMER_ID_MAX then msgId = TASK_TIMER_ID_MAX end
        msgId = msgId + 1
        if timerPool[msgId] == nil then
            timerPool[msgId] = fnc
            break
        end
    end
    --调用底层接口启动定时器
    if rtos.timer_start(msgId, ms) ~= 1 then print("rtos.timer_start error") return end
    --如果存在可变参数，在定时器参数表中保存参数
    if arg.n ~= 0 then
        para[msgId] = arg
    end
    --返回定时器id
    return msgId
end

------------------------------------------ LUA应用消息订阅/发布接口 ------------------------------------------
-- 订阅者列表
local subscribers = {}
--内部消息队列
local messageQueue = {}

local pendingSubscribeReqeusts = {}
local pendingUnsubscribeRequests = {}

--- 订阅消息
-- @param id 消息id
-- @param callback 消息回调处理
-- @usage subscribe("NET_STATUS_IND", callback)
function subscribe(id, callback)
    if type(id) ~= "string" or (type(callback) ~= "function" and type(callback) ~= "thread") then
        print("warning: sys.subscribe invalid parameter", id, callback)
        return
    end
    table.insert(pendingSubscribeReqeusts, {id, callback})
end

--- 取消订阅消息
-- @param id 消息id
-- @param callback 消息回调处理
-- @usage unsubscribe("NET_STATUS_IND", callback)
function unsubscribe(id, callback)
    if type(id) ~= "string" or (type(callback) ~= "function" and type(callback) ~= "thread") then
        print("warning: sys.unsubscribe invalid parameter", id, callback)
        return
    end
    table.insert(pendingUnsubscribeRequests, {id, callback})
end

--- 发布内部消息，存储在内部消息队列中
-- @param ... 可变参数，用户自定义
-- @return 无
-- @usage publish("NET_STATUS_IND")
function publish(...)
    table.insert(messageQueue, arg)
end

-- 分发消息
local function dispatch()
    -- 处理订阅、取消订阅的请求
    for _, req in ipairs(pendingSubscribeReqeusts) do
        local id, callback = req[1], req[2]
        if not subscribers[id] then
            subscribers[id] = {}
        end
        table.insert(subscribers[id], callback)
    end
    pendingSubscribeReqeusts = {}
    
    for _, req in ipairs(pendingUnsubscribeRequests) do
        local id, callback = req[1], req[2]
        if not subscribers[id] then return end
        for i, v in ipairs(subscribers) do
            if v == callback then
                table.remove(subscribers[id], i)
            end
        end
    end
    pendingUnsubscribeRequests = {}
    
    while true do
        if #messageQueue == 0 then
            break
        end
        local message = table.remove(messageQueue, 1)
        if subscribers[message[1]] then
            for _, callback in ipairs(subscribers[message[1]]) do
                if type(callback) == "function" then
                    callback(unpack(message, 2, #message))
                elseif type(callback) == "thread" then
                    coroutine.resume(callback, message[1], {unpack(message, 2, #message)})
                end
            end
        end
    end
end

-- rtos消息回调
local handlers = {}
setmetatable(handlers, {__index = function() return function() end end, })

--- 注册rtos消息回调处理函数
-- @number id 消息类型id
-- @param handler 消息处理函数
-- @return 无
-- @usage rtos.on(rtos.MSG_KEYPAD, function(param) handle keypad message end)
rtos.on = function(id, handler)
    handlers[id] = handler
end

------------------------------------------ Luat 主调度框架  ------------------------------------------
--- run()从底层获取core消息并及时处理相关消息，查询定时器并调度各注册成功的任务线程运行和挂起
-- @return 无
-- @usage sys.run()
function run()
    while true do
        -- 分发内部消息
        dispatch()
        -- 阻塞读取外部消息
        local msg, param = rtos.receive(rtos.INF_TIMEOUT)
        -- 判断是否为定时器消息，并且消息是否注册
        if msg == rtos.MSG_TIMER and timerPool[param] then
            if param < TASK_TIMER_ID_MAX then
                -- print("timerPool[msgPara] is task ----->", param, timerPool[param])
                local taskId = timerPool[param]
                timerPool[param] = nil
                if taskTimerPool[taskId] == param then
                    taskTimerPool[taskId] = nil
                    coroutine.resume(taskId)
                end
            else
                local cb = timerPool[param]
                -- print("timerPool[msgPara] is msg ---->", param, timerPool[param])
                timerPool[param] = nil
                -- print("sys.run msg --> cb", cb)
                if para[param] ~= nil then
                    cb(unpack(para[param]))
                else
                    cb()
                end
            end
        --其他消息（音频消息、充电管理消息、按键消息等）
        else
            handlers[msg](param)
        end
    end
end

require "clib"
