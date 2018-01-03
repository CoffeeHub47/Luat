--- AM2320 温湿度传感器驱动
-- @module AM2320
-- @author 稀饭放姜
-- @license MIT
-- @copyright openLuat.com
-- @release 2017.10.19
require "utils"
module(..., package.seeall)
--- 读取AM2320的数据
-- @number id, 端口号0-2
-- @number addr,从设备地址16进制,如0x3c
-- @return string，string，第一个参数是温度，第二个是湿度
-- @usage tmp, hum = read()
function read(id, addr)
    i2c.send(id, addr, 0x03)
    i2c.send(id, addr, {0x03, 0x00, 0x04})
    -- sys.wait(2)
    local data = i2c.recv(id, addr, 8)
    if data == nil or data == 0 then return end
    log.info("AM2320 data hex: ", data:tohex())
    local _, crc = pack.unpack(data, '<H', 7)
    data = string.sub(data, 1, 6)
    if crc == crypto.crc16_modbus(data, 6) then
        local _, hum, tmp = pack.unpack(string.sub(data, 3, -1), '>h2')
        return tmp, hum
    end
end
