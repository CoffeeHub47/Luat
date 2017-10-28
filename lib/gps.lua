--- 模块功能：GPS模块管理
-- @module gps
-- @author 稀饭放姜，朱工
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2017.10.23
require "pins"
module(..., package.seeall)
-- 模块和单片机通信的串口号，波特率，wake，MCU_TO_GPS,GPS_TO_MCU,ldo对应的IO
local gps_task
local uid, wake, m2g, g2m, ldo = 2
--- 打开GPS模块
-- @return string ,串口的真实波特率
function open()
    pmd.ldoset(7, pmd.LDO_VCAM)
    if ldo then ldo(1) end
    if wake then wake(1) end
    rtos.sys32k_clk_out(1)
    gps_task = coroutine.running()
    if not gps_task then log.warn("gps.open: gps must be called in coroutine!") return end
    uart.setup(uid, 115200, 8, uart.PAR_NONE, uart.STOP_1)
    -- 串口收到数据时唤醒console协程
    uart.on(uid, "receive", function()coroutine.resume(gps_task) end)
end
--- 关闭GPS模块
function close()
    pmd.ldoset(0, pmd.LDO_VCAM)
    if ldo then ldo(0) end
    uart.close(uid)
    rtos.sys32k_clk_out(0)
end

--- 设置GPS模块通信端口
-- @number id,串口号
-- @param w，唤醒GPS模块对应的PIO
-- @param m，mcu发给gps信号的PIO
-- @param g, GSP发给MCU信号的PIO
-- @param vp，GPS的电源供给控制PIO
-- @return 无
-- @usage gps.setup(2,pio.P0_23,pio.P0_22,pio.P0_21,pio.P0_8)
function setup(id, w, m, g, vp)
    uid = id or 2
    wake = pins.setup(w or pio.P0_23, 0)
    m2g = pins.setup(m or pio.P0_22, 0)
    g2m = pins.setup(g or pio.P0_21, 0)
    if vp then ldo = pins.setup(ldo, 0) end
end
-- NMEA模式
local DATA_MODE_NMEA = "AAF00E0095000000C20100580D0A"
-- BINARY模式
local DATA_MODE_BINARY = "$PGKC149,1,115200*"

function read()
    while true do
        local s = uart.read(uid, "*l")
        if s ~= "" then
            return s
        end
        coroutine.yield()
    end
end
function write(str)
    local str = str:tohex()
    uart.write(uid, str)
end

--cmd格式："$PGKC149,1,115200*"
function writeCmd(cmd)
    local tmp = 0
    for i = 2, cmd:len() - 1 do
        tmp = bit.bxor(tmp, cmd:byte(i))
    end
    tmp = cmd .. string.upper(string.format("%02X", tmp)) .. "\r\n"
    uart.write(uid, tmp)
    log.info("gps.writecmd", tmp)
end

--- 更新星历到GPS模块
function update(data)
    local tmp = ""
    if not data then return end
    local function hexCheckSum(str)
        local sum = 0
        for i = 1, str:len(), 2 do
            sum = bit.bxor(sum, tonumber(str:sub(i, i + 1), 16))
        end
        return string.upper(string.format("%02X", sum))
    end
    -- 等待切换到BINARY模式
    writeCmd(DATA_MODE_BINARY)
    while tmp ~= "AAF00C0001009500039B0D0A" do tmp = read():fromhex() end
    -- 写入星历数据
    for i = 1, #data, 512 do
        local cnt = 0 -- 包序号
        tmp = data:sub(i, i + 511)
        if tmp:len() < 512 then tmp = tmp .. ("0"):rep(512 - tmp:len()) end
        tmp = "0B026602" .. string.upper(string.format("%04X", cnt)) .. tmp
        tmp = "AAF0" .. tmp .. hexCheckSum(tmp) .. "0D0A"
        tmp = tmp:tohex()
        log.debug("gps.update sendata:", tmp:fromhex())
        uart.write(uid, tmp)
        -- write(uid, tmp)
        while (read()):len() ~= 0 do break end
        cnt = cnt + 1
    end
    -- 发送GPD传送结束语句
    tmp = string.tohex("aaf00b006602ffff6f0d0a")
    uart.write(uid, tmp)
    while (read()):len() ~= 0 do break end
    -- 切换为NMEA接收模式
    tmp = string.tohex("aaf00e0095000000c20100580d0a")
    uart.write(uid, tmp)
    -- while (read()):len() ~= 0 do break end
    while tmp ~= "AAF00C0001009500039B0D0A" do tmp = read():fromhex() end
end
setup()
