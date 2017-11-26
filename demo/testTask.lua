--- 模块功能：testTask
-- @module test
-- @author openLuat
-- @license MIT
-- @copyright openLuat
-- @release 2017.02.17
require "AM2320"
require "audio"
require "http"
require "mono_lcd_i2c_ssd1306"
module(..., package.seeall)

sys.taskInit(function()
    if i2c.setup(2, i2c.SLOW) ~= i2c.SLOW then
        log.error("I2C.init is: ", "fail")
    end
    ccnt = 0
    while true do
        mono_lcd_i2c_ssd1306.init(2, 0x3c)
        local tmp, hum = AM2320.read(2, 0x5c)
        print("tastTask.AM2320 data is : ", tmp, hum, ccnt)
        ccnt = ccnt + 1
        sys.wait(6000)
    -- audio.chime()
    end
end)
-- 测试HTTP任务
sys.taskInit(function()
    while true do
        while not socket.isReady() do sys.wait(1000) end
        local code, head, body = http.request("GET", "http://www.nmc.cn/f/rest/real/54511", 1000)
        log.info("testTask.http test body is length:\t", code, head, string.len(body))
        for k, v in pairs(head) do print("testTask.http head :\t", k, v) end
        sys.wait(60000)
        code, head, body = http.request("GET", "download.openluat.com/9501-xingli/brdcGPD.dat_rda", 1000)
        log.info("testTask.http test body is length:\t", code, head, string.len(body))
        sys.wait(60000)
    end
end)

sys.taskInit(function()
    cnt = 0
    while true do
        print("taskOne__test cnt: ", cnt)
        cnt = cnt + 1
        sys.wait(100)
    end
end)
