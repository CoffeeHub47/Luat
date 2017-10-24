--- 模块功能：testTask
-- @module test
-- @author openLuat
-- @license MIT
-- @copyright openLuat
-- @release 2017.02.17
require "AM2320"
require "audio"
require "http"
-- local lcd = require "mono_lcd_i2c_ssd1306"
module(..., package.seeall)
sys.taskInit(function()
    AM2320.open()
    -- lcd.init()
    while true do
        print("tastTask.AM2320 data is :\t", AM2320.read())
        sys.wait(60000)
        audio.chime()
    end
end)
-- 测试HTTP任务
sys.taskInit(function()
    while true do
        sys.wait(20000)
        body = http.request("GET", "download.openluat.com/9501-xingli/brdcGPD.dat_rda", 5000)
        print("http.body is length:\t", #body)
        print("http.body is content:\t", body)
    end
end)
