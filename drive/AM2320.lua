--- AM2320 温湿度传感器驱动
-- @module AM2320
-- @author 稀饭放姜
-- @license MIT
-- @copyright openLuat.com
-- @release 2017.10.19
require "utils"
module(..., package.seeall)
-- I2C的物理端口号, 从设备的地址
local i2cid, i2cslaveaddr = 2, 0x5C
--- 设置I2C的物理端口和从设备地址
-- @number id, 端口号0-2
-- @number addr,从设备地址16进制,如0x3c
-- @return 无
-- @usage setup(2,0x3c)
function setup(id, addr)
    i2cid = id or 2
    i2cslaveaddr = addr or 0x3c
end
--- 唤醒并打开对应的I2C设备
-- @return 无
-- @usage open()
function open()
    --注意：此处的i2cslaveaddr是7bit地址
    --如果i2c外设手册中给的是8bit地址，需要把8bit地址右移1位，赋值给i2cslaveaddr变量
    --如果i2c外设手册中给的是7bit地址，直接把7bit地址赋值给i2cslaveaddr变量即可
    --发起一次读写操作时，启动信号后的第一个字节是命令字节
    --命令字节的bit0表示读写位，0表示写，1表示读
    --命令字节的bit7-bit1,7个bit表示外设地址
    --i2c底层驱动在读操作时，用 (i2cslaveaddr << 1) | 0x01 生成命令字节
    --i2c底层驱动在写操作时，用 (i2cslaveaddr << 1) | 0x00 生成命令字节
    if i2c.setup(i2cid, i2c.SLOW, i2cslaveaddr) ~= i2c.SLOW then
        print("______AM2320.init fail______")
        return
    end
end
--- 读取AM2320的数据
-- @return string，string，第一个参数是温度，第二个是湿度
-- @usage tmp, hum = read()
function read()
    i2c.write(i2cid, 0x03)
    i2c.write(i2cid, pack.pack('bbb', 0x03, 0x00, 0x04))
    sys.wait(2)
    local data = i2c.read(i2cid, 8)
    if data == nil or data == "" then return end
    local _, crc = pack.unpack(data, '<H', 7)
    data = string.sub(data, 1, 6)
    if crc == crypto.crc16_modbus(data, 6) then
        local _, hum, tmp = pack.unpack(string.sub(data, 3, 6), '>hh')
        return tmp, hum
    end
end
--- 关闭I2C模块单元
-- @return 返回值为I2C模块对应的速率
-- @usage speed = close()
function close()
    return i2c.close(i2cid)
end
