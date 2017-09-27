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
-- 缓冲区最大下标
local bufferIndexMax = 49
-- read函数缓冲区
local readBuffer = {}
-- 缓冲区下标
local buffIndex = 0
-- 缓冲区溢出操作模式"cover" or "discard"
local overflow = "cover"
-- read函数过滤器
local readFilter

--[[
订阅ID通道的链接请求结果
该函数在connect中订阅的链接消息
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
    
    for i = 1, len, SENDSIZE do
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
function read(protocol, size)
    if protocol == "UDP" then
        -- 将 readBuffer 当作FIFO 缓冲区，先进先出。
        return table.remove(readBuffer, 1)
    elseif protocol == "TCP" then
        -- 将缓冲区的数据链接成字符串
        readStream = table.concat(readBuffer, "")
        -- 清空缓冲区
        readBuffer = {}
        -- 如果用户输入的参数
        if size == nil or size >= string.len(readStream) then
            return readStream
        else
            local data = string.sub(readStream, 1, size)
            readStream = string.sub(readStream, size + 1, -1)
            table.insert(readBuffer, readStream)
            return data
        end
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
    rid = tonumber(rid)
    len = tonumber(len)
    -- 如果len为0，或者id 不是本实例的ID，则说明不是read需要的数据，发给ril继续处理
    if len == 0 or rid ~= self.id then return data end
    -- 处理缓冲区溢出模式
    if buffIndex >= bufferIndexMax then if overflow == "cover" then buffIndex = 0 else return end end
    -- 注册ril.procat 过滤器
    readFilter = function(dat)
        len = len - string.len(dat)
        -- 写入缓冲区的次数加1
        buffIndex = buffIndex + 1
        if len == 0 then
            -- 数据接收完成通知用户读取消息
            table.insert(readBuffer, dat)
            return ""
        elseif len > 0 then
            -- “+RECEIVE” 返回的数据分包了
            table.insert(readBuffer, dat)
            return "", readFilter
        else
            -- 如果小于0，说明包中含有别的命令的信息，扔回给ril.procatc处理
            -- 截取剩余的包
            table.insert(readBuffer, string.sub(dat, 1, len))
            -- 分离别的命令返回的信息
            dat = string.sub(dat, len + 1, -1)
            return dat, readFilter
        end
    end
    return readFilter
end

ril.regurc("+RECEIVE", receive)
-- 订阅linK.lua模块的IP服务激活和注销消息
subscribe("IP_STATUS_SUCCESS", function()ipStatus = true end)
subscribe("CONNECTION_LINK_ERROR", function()ipStatus = false end)
