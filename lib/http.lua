--- 模块功能：HTTP客户端
-- @module http
-- @author 稀饭放姜
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2017.10.23
require "socket"
require "utils"
module(..., package.seeall)

local Content_type = {"application/x-www-form-urlencoded", "application/json", "application/octet-stream", }

-- 处理表的url编码
function urlencodeTab(params)
    local msg = {}
    for k, v in pairs(params) do
        table.insert(msg, string.urlencode(k) .. "=" .. string.urlencode(v))
        table.insert(msg, "&")
    end
    table.remove(msg)
    return table.concat(msg)
end
--- HTTP客户端
-- @string method,提交方式"GET" or "POST"
-- @string url,HTTP请求超链接
-- @number timeout,超时时间
-- @param params,table类型，请求发送的查询字符串，通常为键值对表
-- @param data,table类型，正文提交的body,通常为键值对、json或文件对象类似的表
-- @number ctype,Content-Type的类型(可选1,2,3),默认1:"urlencode",2:"json",3:"octet-stream"
-- @string basic,HTTP客户端的authorization basic验证的"username:password"
-- @param headers,table类型,HTTP headers部分
-- @return string,table,string,正常返回response_code, response_header, response_body
-- @return string,string,错误返回 response_code, error_message
-- @usage local c, h, b = http.request(url, method, headers, body)
-- @usage local r, e  = http.request("http://wrong.url/ ")
function request(method, url, timeout, params, data, ctype, basic, headers)
    local response_header, response_code, response_message, response_body, host, port, path, str, sub, len = {}
    local headers = headers or {
        ["User-Agent"] = "Mozilla/4.0",
        ["Accept"] = "*/*",
        ["Accept-Language"] = "zh-CN,zh,cn",
        ["Content-Type"] = "application/x-www-form-urlencoded",
        ["Content-Length"] = "0",
        ["Connection"] = "close",
    }
    -- 判断SSL支持是否满足
    local ssl, https = string.find(rtos.get_version(), "SSL"), url:find("https://")
    if ssl == nil and https then return "401", "SOCKET_SSL_ERROR" end
    -- 对host:port整形
    if url:find("://") then url = url:sub(8) end
    sub = url:find("/")
    if not sub then url = url .. "/"; sub = -1 end
    str = url:match("([%w%.%-%:]+)/")
    port = str:match(":(%d+)") or 80
    host = str:match("[%w%.%-]+")
    path = url:sub(sub)
    sub = ""
    -- 处理查询字符串
    if params ~= nil and type(params) == "table" then path = path .. "?" .. urlencodeTab(params) end
    -- 处理HTTP协议body部分的数据
    if data ~= nill and type(data) == "table" or type(data) == "string" then
        headers["Content-Type"] = Content_type[ctype]
        if ctype == 1 then sub = urlencodeTab(data) end
        if ctype == 2 then sub = json.encode(data) end
        if ctype == 3 then sub = table.concat(data) end
        len = string.len(sub)
        headers["Content-Length"] = len or 0
    end
    -- 处理HTTP Basic Authorization 验证
    if basic ~= nil and type(basic) == "string" then
        headers["Authorization"] = "Basic " .. crypto.base64_encode(basic, #basic)
    end
    -- 处理headers部分
    local msg = {}
    for k, v in pairs(headers) do
        table.insert(msg, k .. ": " .. v)
    end
    -- 合并request报文
    str = str .. "\n" .. table.concat(msg, "\n") .. "\n\n"
    str = method .. " " .. path .. " HTTP/1.0\nHost: " .. str .. sub .. "\n"
    -- log.info("http.request send:", str:tohex())
    -- 发送请求报文
    local c = socket.tcp()
    if not c:connect(host, port) then c:close() return "502", "SOCKET_CONN_ERROR" end
    if not c:send(str) then c:close() return "426", "SOCKET_SEND_ERROR" end
    r, s = c:recv(timeout)
    if not r then return "503", "SOCKET_RECV_TIMOUT" end
    response_code = s:match(" (%d+) ")
    response_message = s:match(" (%a+)")
    log.info("http.response code and message:\t", response_code, response_message)
    for k, v in s:gmatch("([%a%-]+): (%C+)") do response_header[k] = v end
    gzip = s:match("%aontent%-%ancoding: (%a+)")
    msg = {}
    while true do
        r, s = c:recv(timeout)
        if not r then break end
        table.insert(msg, s)
    end
    c:close()
    if gzip then return response_code, response_header, ((zlib.inflate(table.concat(msg))):read()) end
    return response_code, response_header, table.concat(msg)
end
