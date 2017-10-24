--- 模块功能：HTTP客户端
-- @module http
-- @author 稀饭放姜
-- @lincense MIT
-- @copyright OpenLuat.com
-- @release 2017.10.23
require "socket"
require "utils"
module(..., package.seeall)
--[[错误消息预定义
"SOCKET_SSL_ERROR"
"SOCKET_CONN_ERROR"
"SOCKET_SEND_ERROR"
SOCKET_RECV_TIMOUT
--]]
local message = {
    "GET ",
    " ",
    "head",
    " HTTP/1.1\n",
    "Accept: */*\n",
    "Accept-Language: zh-CN,zh,cn\n",
    "User-Agent: Mozilla/4.0\n",
    "Host: ",
    "wthrcdn.etouch.cn",
    "\n",
    "Content-Type: application/x-www-form-urlencoded\n",
    "Content-Length: ",
    "0",
    "\n",
    "Connection: close\n\n",
    ""
}
--- 创建HTTP客户端
-- @string put,提交方式"GET" or "POST"
-- @string url,HTTP请求超链接
-- @number timeout,超时时间
-- @string data,"POST"提交的数据表
-- @return string ,HttpServer返回的数据
function request(put, url, timeout, data)
    -- 数据，端口,主机,
    local msg, port, host, len, sub, head, str = {}
    -- 判断SSL支持是否满足
    local ssl, https = string.find(rtos.get_version(), "SSL"), url:find("https://")
    if ssl == nil and https then return "SOCKET_SSL_ERROR" end
    -- 对host:port整形
    if url:find("://") then url = url:sub(8) end
    sub = url:find("/")
    if not sub then url = url .. "/"; sub = -1 end
    str = url:match("([%w%.%-%:]+)/")
    port = str:match(":(%d+)") or 80
    host = str:match("[%w%.%-]+")
    head = url:sub(sub)
    if type(data) == "table" then
        for k, v in pairs(data) do
            table.insert(msg, k .. "=" .. v)
            table.insert(msg, "&")
        end
        table.remove(msg)
        str = table.concat(msg)
        len = str:utf8len()
        str = string.urlencoded(str)
    else
        len = 0
        str = ""
    end
    message[1] = put
    message[3] = head
    message[9] = host
    message[13] = len
    message[16] = str
    str = table.concat(message)
    local c = socket.tcp()
    if not c:connect(host, port) then c:close() return "SOCKET_CONN_ERROR" end
    if not c:send(str) then c:close() return "SOCKET_SEND_ERROR" end
    local r, s = c:recv(timeout)
    len = string.match(s, "%w+%-%w+%:.(%d+)")
    print("http.request recv is:\t", tonumber(len))
    c:close()
    if not r then return "SOCKET_RECV_TIMOUT" end
    return s
end
