--- 模块功能：MQTT-V3.1.1客户端
-- @module mqtt
-- @author 稀饭放姜 小强
-- @license MIT
-- @copyright openLuat.com
-- @release 2017.10.25
require "socket"
module(..., package.seeall)

--[[
mqttc:on("message", function(data) print("receive data", data)end)
mqttc:on("connect", function()print("connect success")end)
mqttc:on("disconnect", function()print("disconnect")end)
mqttc:on("publish", function(mid) print("publish success", mid)end)
-]]
local mqtt = {}
mqtt.__index = mqtt
--- 创建MQTT客户端
-- @string clientID, 客户端的唯一标识ID
-- @string prot,MQTT通信协议"UDP" or "TCP"
-- @string cleanSession,
-- @return table,返回一个类的实例
function create(clientID, prot, cleanSession)
    local o = {id = clientID, port = port, cs = cleanSession}
    return setmetatable(o, mqtt)
end

function mqtt:connect(host, port, username, password, keepalive)

end

function mqtt:publish(topic, payload, qos, retain, will)
    
    return mid
end

function mqtt:subscribe(topic, qos)

end

function mqtt:unSubscribe(topic, qos)

end
function mqtt:close()
end

function mqtt:on(msg, fun)

end
