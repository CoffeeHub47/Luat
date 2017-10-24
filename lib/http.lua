--- 模块功能：HTTP客户端
-- @module http
-- @author 稀饭放姜
-- @lincense MIT
-- @copyright OpenLuat.com
-- @release 2017.10.23
require("socket")
module(..., package.seall)
-- 错误消息预定义
local SOCKET_SSL_ERROR = 0
local SOCKET_ERROR = 1

--- 创建HTTP客户端
-- @param c,socket 对象实例
-- @return table,返回一个http客户端的实例
function request(type, url)
    local ssl = string.find(rtos.get_version(), "SSL")
    local https = string.find(url, "https://")
    if ssl == nil and https then return SOCKET_SSL_ERROR end
    local index = string.find(url, "://")
    if index then index = index + 3 else index = 1 end
    -- 查找"http://"后到第一个"/"之间存在@符号没有
    local auth = string.find(url, "@")
    local sub = string.find(url, "/", index)
    -- 如果找到@在"/"之前，将@之前的字符串赋值给usr
    if auth and sub > auth then
        local usr = string.sub(url, index, auth)
        index = auth + 1
    end
    local host = string.
        local c = socket.tcp()
    if not c:connect(host, port) then return SOCKET_ERROR end

end
