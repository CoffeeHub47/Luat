--- 模块功能：testTask
-- @module test
-- @author openLuat
-- @license MIT
-- @copyright openLuat
-- @release 2017.02.17
require "AM2320"
-- local lcd = require "mono_lcd_i2c_ssh1306"
module(..., package.seeall)
sys.taskInit(function()
    AM2320.open()
    -- lcd.init()
    while true do
        print("tastTask.AM2320 data is :\t", AM2320.read())
        sys.wait(2000)
    end
end)
