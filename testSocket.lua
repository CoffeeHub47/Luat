--- testSocket
-- @module testSocket
-- @author 小强
-- @license MIT
-- @copyright openLuat.com
-- @release 2017.9.27

require "socket"
module(..., package.seeall)

-- tcp test
sys.taskInit(function()
    local r, s

    while true do
        local c = socket.tcp()

        while not c:connect("36.7.87.100", 6188) do
            sys.wait(2000)
        end

        while true do
            if not c:send("12345678") then
                break
            end

            r, s = c:recv()
            if not r then
                break
            end

            print("test.socket.tcp: recv", s)
        end

        c:close()
    end
end)

-- udp test
sys.taskInit(function()
    local r, s

    while true do
        local c = socket.udp()

        while not c:connect("36.7.87.100", 6189) do
            sys.wait(2000)
        end

        while true do
            if not c:send("12345678") then
                break
            end

            r, s = c:recv()
            if not r then
                break
            end

            print("test.socket.udp: recv", s)
        end

        c:close()
    end
end)
