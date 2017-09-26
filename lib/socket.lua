--- 数据链路激活、SOCKET管理(创建、连接、数据收发、状态维护)
-- @module link
-- @author 稀饭放姜、小强
-- @license MIT
-- @copyright openLuat.com
-- @release 2017.9.25
module(..., package.seeall)
local wait = sys.wait
local waitUntil = sys.waitUntil
local publish = sys.publish
local subscribe = sys.subscribe
local request = ril.request

-- 可用socket id列表，最大支持8个连接
local valid = {0, 1, 2, 3, 4, 5, 6, 7}
-- GPRS的IP服务是否激活
local ipStatus = false
-- 单次发送数据最大值
local SENDSIZE = 1460
-- socket连接表
local linkList = {}
-- socket发起连接请求后，响应间隔超时策略："restart" or "reconn"
local reconnStrategy = "reconn"
-- socket发起连接请求后，响应间隔ms
local reconnInterval


--[[
订阅ID通道的链接请求结果
--]]
local function urc()
    -- socket 状态通知
    local cid, state = string.match(data, "(%d), *([%u :%d]+)")
    -- socket 链接失败，执行断开链接动作
    if state ~= "CONNECT OK" then
        close(cid)
    end
end
--- socket服务连接服务器请求
-- @string protocol,协议只支持”tcp"or"udp"
-- @string address,服务器地址
-- @number port,服务器端口
-- @return number,创建连接成功返回ID，创建失败返回-1；
function connect(protocol, address, port)
    -- 输出参数检查
    assert(type(protocol) == "string", "This first parameter is not a concatenated string!")
    assert(type(address) == "string", "This second parameter is not a concatenated string!")
    assert(type(port) == "number", "This laster parameter is not a concatenated number!")
    -- 生成链接所需ID
    local id = table.remove(valid)
    --不允许发起连接动作
    if id == nil then
        print("socket.tcp : Links exceed the maximum value! \t", protocol, address, port)
        return -1
    end
    --如果打开了通话功能 并且当前正在通话中使用异步通知连接失败
    if cc and cc.anycallexist() then
        print("socket.tcp : failed cause call exist!")
        publish("LINK_ASYNC_LOCAL_EVENT", id, "CONNECT FAIL")
        return -1
    end
    
    -- 等待IP服务激活后创建链接，如果IP服务没有激活，先加入到队列
    if ipstatus then
        --发送建立链接请求
        request(string.format("AT+CIPSTART=%d,\"%s\",\"%s\",%s", id, protocol, address, port))
        --注册连接urc
        ril.regurc(tostring(id), urc)
    else
        --ip服务没有激活，返回false并打印原因
        print("socket.tcp : Create Tcp link is failed, GPRS IP SERVER is not activate!")
        return -1
    end
    return id
end

--- 关闭指定ID的链接
-- @number id, socket 链接的ID
-- @return 无
-- @usage s_socket:close(0)
function close(id)
    -- 关闭链接操作
    request("AT+CIPCLOSE=" .. id)
    -- 回收ID
    table.insert(valid, id)
end

--- socket 发送数据函数
-- @param
-- @
-- @return
-- @usage
function send(id, data)
    local len = string.len(data)
    if len == 0 then print("socket.send : Send data empyt!") return end
    
    for i = 0, len, SENDSIZE do
        -- 按最大MTU单元对data分包
        local setpData = string.sub(data, i, i + SENDSIZE - 1)
        --发送AT命令执行数据发送
        request(string.format("AT+CIPSEND=%d,%d", id, string.len(setpData), setpData))
    end
end

--- socket 读取数据函数
-- @param
-- @param
-- @return
-- @usage
function read(id)

end

--[[
函数名：rcvdfilter
功能  ：从AT通道收取一包数据
参数  ：
data：解析到的数据
返回值：两个返回值，第一个返回值表示未处理的数据，第二个返回值表示AT通道的数据过滤器函数
]]
local function rcvdfilter(data)
    --如果总长度为0，则本函数不处理收到的数据，直接返回
    if rcvd.len == 0 then
        return data
    end
    --剩余未收到的数据长度
    local restlen = rcvd.len - string.len(rcvd.data)
    if string.len(data) > restlen then -- at通道的内容比剩余未收到的数据多
        -- 截取网络发来的数据
        rcvd.data = rcvd.data .. string.sub(data, 1, restlen)
        -- 剩下的数据仍按at进行后续处理
        data = string.sub(data, restlen + 1, -1)
    else
        rcvd.data = rcvd.data .. data
        data = ""
    end
    
    if rcvd.len == string.len(rcvd.data) then
        --通知接收数据
        recv(rcvd.id, rcvd.len, rcvd.data)
        rcvd.id = 0
        rcvd.len = 0
        rcvd.data = ""
        return data
    else
        return data, rcvdfilter
    end
end

--[[
函数名：receive
功能  ：socket 数据接收服务
参数  ：
data：通知的完整字符串信息
prefix：通知的前缀
返回值：无
]]
local function receive(data, prefix)
    local rid, len = string.match(data, ",(%d),(%d+)", string.len("+RECEIVE") + 1)
    rcvd.id = tonumber(lid)
    rcvd.len = tonumber(len)
    return rcvdfilter
end

ril.regurc("+RECEIVE", receive)
-- 订阅linK.lua模块的IP服务激活和注销消息
subscribe("IP_STATUS_SUCCESS", function()ipStatus = true end)
subscribe("CONNECTION_LINK_ERROR", function()ipStatus = false end)
