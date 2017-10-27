--- 模块功能：GPS模块管理
-- @module gps
-- @author 稀饭放姜，朱工
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2017.10.23
require "pins"
require "common"
module(..., package.seeall)
-- 模块和单片机通信的串口号，波特率，wake，MCU_TO_GPS,GPS_TO_MCU,ldo对应的IO
local uid, wake, m2g, g2m, ldo = 2
--- 打开GPS模块
-- @return string ,串口的真实波特率
function open()
    pmd.ldoset(7, pmd.LDO_VCAM)
    if ldo then ldo(1) end
    if wake then wake(1) end
    rtos.sys32k_clk_out(1)
    return uart.setup(uid, 115200, 8, uart.PAR_NONE, uart.STOP_1)
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

--cmd格式："$PGKC149,1,115200*"
function writecmd(cmd)
    log.info("gps.writecmd", cmd)
    local tmp, i = 0
    for i = 2, cmd:len() - 1 do
        tmp = bit.bxor(tmp, cmd:byte(i))
    end
    tmp = string.upper(string.format("%02X", tmp))
    uart.write(uid, cmd .. tmp .. "\r\n")
end

function read()
    return uart.read(uid, "*l", 0)
end

setup()
open()
writecmd("$PGKC149,1,115200*")
-- uart.write(uid, common.hexstobins("AAF00E0095000000C20100580D0A"))
-- read()
sys.taskInit(function()
    while true do
        local str = read()
        if not str then break end
        print("gps.read:\t", str)
        print("gps.read:\t", utils.hexlify(str))
        sys.wait(10)
    end
end)
