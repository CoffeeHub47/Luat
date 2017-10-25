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
    -- audio.chime()
    end
end)
-- 测试HTTP任务
sys.taskInit(function()
    while true do
        while not socket.isReady() do sys.wait(1000) end
        -- body = http.request("GET", "download.openluat.com/9501-xingli/brdcGPD.dat_rda", 5000)
        local body = http.request("GET", "http://wthrcdn.etouch.cn/weather_mini?city=%E5%8C%97%E4%BA%AC", 5000)
        sys.wait(60000)
    end
end)
