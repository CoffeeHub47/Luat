--- 常用工具类接口
-- @module utils
-- @author 小强
-- @license MIT
-- @copyright openLuat.com
-- @release 2017.9.25

module(..., package.seeall)

function hexlify(str)
    return str:gsub('.', function(c)
        return string.format("%02X", string.byte(c))
    end)
end
