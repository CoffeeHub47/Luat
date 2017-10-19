--- 常用工具类接口
-- @module utils
-- @author 小强
-- @license MIT
-- @copyright openLuat.com
-- @release 2017.10.19

module(..., package.seeall)

--- 返回字符串的16进制表示
-- @param str 输入字符串
-- @return hexstring 16进制字符串
-- @return len 输入的字符串长度
-- @usage
-- hexlify("\1\2\3") -> "010203"
-- hexlify("123abc") -> "313233"
function hexlify(str)
    return str:gsub('.', function(c)
        return string.format("%02X", string.byte(c))
    end)
end
