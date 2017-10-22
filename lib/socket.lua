--- 数据链路激活、SOCKET管理(创建、连接、数据收发、状态维护)
-- @module link
-- @author 稀饭放姜、小强
-- @license MIT
-- @copyright openLuat.com
-- @release 2017.9.25
require("link")
-- require("log")
module(..., package.seeall)

local valid = {"0", "1", "2", "3", "4", "5", "6", "7"}
local sockets = {}
-- 单次发送数据最大值
local SENDSIZE = 1460
-- 缓冲区最大下标
local INDEX_MAX = 49
-- ip 服务激活标志
local ipStatus = false
sys.subscribe("IP_STATUS_SUCCESS", function()ipStatus = true end)
sys.subscribe("CONNECTION_LINK_ERROR", function()ipStatus = false end)

--[[
订阅rsp返回的消息处理函数
]]
local function onSocketURC(data, prefix)
    local id, result = string.match(data, "(%d), *([%u :%d]+)")
    if not sockets[id] then
        log.error('socket: response on nil socket', cmd, response)
        return
    end
    
    if result == "CONNECT OK" or result == "CONNECT FAIL" then
        if sockets[id].wait == "+CIPSTART" then
            coroutine.resume(sockets[id].co, result == "CONNECT OK")
        else
            log.error("socket: error urc", sockets[id].wait)
        end
        return
    end
    
    if string.find(result, "ERROR") or result == "CLOSED" then
        coroutine.resume(sockets[id].co, false)
    end
end

-- 创建socket函数
local mt = {__index = {}}
local function socket(protocol)
    local id = table.remove(valid)
    if not id then
        log.warn("socket.socket: too many sockets")
        return nil
    end
    
    local co = coroutine.running()
    if not co then
        log.warn("socket.socket: socket must be called in coroutine")
        return nil
    end
    -- 实例的属性参数表
    local o = {
        id = id,
        protocol = protocol,
        co = co,
        input = {},
        wait = "",
    }
    
    sockets[id] = o
    
    return setmetatable(o, mt)
end

--- 创建基于TCP的socket对象
-- @return 无
-- @usage c = socket.tcp()
function tcp()
    return socket("TCP")
end

--- 创建基于UDP的socket对象
-- @return 无
-- @usage c = socket.udp()
function udp()
    return socket("UDP")
end

--- socket:connect 连接服务器
-- @param address ip地址或者域名
-- @param port 端口
-- @return result true - 成功，false - 失败
-- @usage  c = socket.tcp(); c:connect();
function mt.__index:connect(address, port)
    assert(self.co == coroutine.running(), "socket:connect: coroutine mismatch")
    
    if not ipStatus then
        log.info("socket.connect: ip not ready")
        return false
    end
    
    if cc and cc.anycallexist() then
        log.info("socket:connect: call exist, cannot connect")
        return false
    end
    
    ril.request(string.format("AT+CIPSTART=%d,\"%s\",\"%s\",%s", self.id, self.protocol, address, port))
    ril.regurc(self.id, onSocketURC)
    self.wait = "+CIPSTART"
    return coroutine.yield()
end

--- socket:send
-- @param data 数据
-- @return result true - 成功，false - 失败
-- @usage  c = socket.tcp(); c:connect(); c:send("12345678");
function mt.__index:send(data)
    sys.publish("SOCKET_ACTIVE")
    assert(self.co == coroutine.running(), "socket:send: coroutine mismatch")
    for i = 1, string.len(data), SENDSIZE do
        -- 按最大MTU单元对data分包
        local stepData = string.sub(data, i, i + SENDSIZE - 1)
        --发送AT命令执行数据发送
        ril.request(string.format("AT+CIPSEND=%d,%d", self.id, string.len(stepData)), stepData)
        self.wait = "+CIPSEND"
        if not coroutine.yield() then return false end
    end
    sys.publish("IP_STATUS_SUCCESS")
    return true
end

--- socket:recv
-- @return result true - 成功，false - 失败
-- @return data 如果成功的话，返回接收到的数据
-- @usage  c = socket.tcp(); c:connect(); result, data = c:recv()
function mt.__index:recv()
    assert(self.co == coroutine.running(), "socket:recv: coroutine mismatch")
    
    if #self.input == 0 then
        self.wait = "+RECEIVE"
        return coroutine.yield()
    end
    
    if self.protocol == "UDP" then
        return true, table.remove(self.input)
    else
        local s = table.concat(self.input)
        self.input = {}
        return true, s
    end
end

--- socket:close
-- @return 无
-- @usage  c = socket.tcp(); c:connect(); c:send("123"); c:close()
function mt.__index:close()
    assert(self.co == coroutine.running(), "socket:close: coroutine mismatch")
    ril.request("AT+CIPCLOSE=" .. self.id)
    self.wait = "+CIPCLOSE"
    coroutine.yield()
    print("socket.close is tag ------------")
    ril.deregurc(self.id, onSocketURC)
    table.insert(valid, self.id)
    sockets[self.id] = nil
    self.id = nil
end

local function onResponse(cmd, success, response, intermediate)
    local prefix = string.match(cmd, "AT(%+%u+)")
    local id = string.match(cmd, "AT%+%u+=(%d)")
    print("socket.onResponse is running ---------------",prefix)
    if not sockets[id] then
        log.warn('socket: response on nil socket', cmd, response, sockets[id])
        return
    end
    
    if sockets[id].wait == prefix then
        if prefix == "+CIPSTART" and success then
            -- CIPSTART 返回OK只是表示被接受
            return
        end
        print("socket is resue runing:\t ", prefix)
        coroutine.resume(sockets[id].co, success)
    end
end

ril.regrsp("+CIPCLOSE", onResponse)
ril.regrsp("+CIPSEND", onResponse)
ril.regrsp("+CIPSTART", onResponse)

ril.regurc("+RECEIVE", function(urc, prefix)
    local id, len = string.match(urc, ",(%d),(%d+)", string.len("+RECEIVE") + 1)
    len = tonumber(len)
    if len == 0 then return urc end
    sys.publish("SOCKET_ACTIVE")
    local cache = {}
    local function filter(data)
        --剩余未收到的数据长度
        if string.len(data) >= len then -- at通道的内容比剩余未收到的数据多
            -- 截取网络发来的数据
            table.insert(cache, string.sub(data, 1, len))
            -- 剩下的数据仍按at进行后续处理
            data = string.sub(data, len + 1, -1)
            if not sockets[id] then
                log.warn('socket: receive on nil socket', id)
            else
                local s = table.concat(cache)
                if sockets[id].wait == "+RECEIVE" then
                    coroutine.resume(sockets[id].co, true, s)
                else -- 数据进缓冲区，缓冲区溢出采用覆盖模式
                    if #sockets[id].input > INDEX_MAX then sockets[id].input = {} end
                    table.insert(sockets[id].input, s)
                end
            end
            return data
        else
            table.insert(cache, data)
            len = len - string.len(data)
            sys.publish("IP_STATUS_SUCCESS")
            return "", filter
        end
    end
    return filter
end)
