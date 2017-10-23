--- 模块功能：GPS模块管理
-- @module gps
-- @author 稀饭放姜，朱工
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2017.10.23
requice "pins"
module(..., package.seeall)
-- 模块和单片机通信的串口号，波特率，wake，MCU_TO_GPS,GPS_TO_MCU,ldo对应的IO
local uid, wake, m2g, g2m, ldo = 2
--- 打开GPS模块
-- @return string ,串口的真实波特率
function open()
    pmd.ldoset(7, pmd.LDO_VCAM)
    if ldo then ldo(1) end
    return uart.setup(uid, 115200, 8, uart.PAR_NONE, uart.STOP_1)
end
--- 关闭GPS模块
function close()
    pmd.ldoset(0, pmd.LDO_VCAM)
    if ldo then ldo(0) end
    uart.close(uid)
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
    wake = w or pio.P0_23
    m2g = m or pio.P0_22
    g2m = g or pio.P0_21
    if vp then ldo = pins.setup(ldo, 0) end
end
