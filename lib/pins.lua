--- 模块功能：GPIO 功能配置，包括输入输出IO和上升下降沿中断IO
-- @module pins
-- @author 稀饭放姜
-- @license MIT
-- @copyright openLuat
-- @release 2017.09.23 11:34
module(..., package.seeall)
local base = _G
local assert = base.assert
local print = base.print
--- 自适应GPIO模式
-- @param pin ，参数为pio.P0_1-31 和 pio_P1_1-31 (IO >= 32 and IO - 31)
-- @number val，输出模式默认电平：0 是低电平1是高电平，中断模式填nil或0 or 1
-- @string fnc, 中断按键回调函数，用来捆绑按键
-- @return function ,返回一个函数，该函数接受一个参数用来设置IO的电平
-- @usage key = pins.setup(pio.P1_1,0,"IT") ，配置Key的IO为pio.32,中断模式，下降沿触发。用key()获取当前电平
-- @usage led = pins.setup(pio.P1_1,0) ,配置LED脚的IO为pio.32，输出模式，默认输出低电平。led(1)即可输出高电平
-- @usage key = pins.setup(pio.P1_1),配置key的IO为pio.32，输入模式,用key()即可获得当前电平
function setup(pin, val, fnc)
    -- 关闭该IO
    pio.pin.close(pin)
    -- 中断模式配置
    if type(fnc) == "function" then
        pio.pin.setdir(pio.INT, pin)
        --注册引脚中断的处理函数
        rtos.on(rtos.MSG_INT, fnc)
    end
    -- 输出模式初始化默认配置
    if val ~= nil then
        pio.pin.setdir(pio.OUTPUT, pin)
        pio.pin.setval(val, pin)
    -- 输入模式初始化默认配置
    else
        pio.pin.setdir(pio.INPUT, pin)
    end
    -- 返回一个自动切换输入输出模式的函数
    return function(val)
        pio.pin.close(pin)
        if val ~= nil then
            pio.pin.setdir(pio.OUTPUT, pin)
            pio.pin.setval(val, pin)
            -- print("pins.setup is output1 model\t pio.p_", pin)
            pio.pin.setval(val, pin)
        else
            pio.pin.setdir(pio.INPUT, pin)
            -- print("pins.setup is input1 model\t pio.p_", pin)
            return pio.pin.getval(pin)
        end
    end
end
