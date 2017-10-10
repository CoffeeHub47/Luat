module(..., package.seeall)
require "mono_lcd_spi_ssh1106"
require "config"
require "pins"
-- 菜单条的菜单图标列表
local menuBar = config.rootMenu



--从坐标16,0位置开始显示"欢迎使用Luat"
-- disp.puttext("-- 语言菜单 --", 0, 0)
-- disp.puttext("   英文菜单", 0, 16)
-- disp.puttext(" > 德文菜单", 0, 32)
-- disp.puttext("   日文菜单", 0, 48)
--显示logo图片
-- disp.setcolor(0x0000)
-- disp.drawrect(0,32,64,32,0xffff)
-- disp.setcolor(0xffff)
-- disp.putimage("/ldata/msg.bmp", 32, 0, -1)
-- disp.putimage("/ldata/device_small.bmp", 0, 12)
-- disp.putimage("/ldata/menu_small.bmp", 96, 12)
-- -- disp.putimage("/ldata/2.bmp",64,0,-1)
-- -- disp.putimage("/ldata/up.bmp",56,16)
function append(fname)
    menuBar = {}
    f = io.open("/ldata/" .. fname .. ".ini")
    for s in f:lines() do table.insert(menuBar, s) end
    f.close()
end

function changeMenu(id)
    if id <= 0 then id = #menuBar end
    for i = 1, id do
        table.insert(menuBar, table.remove(menuBar, 1))
    end
end

function displayMenu()
    --清空LCD显示缓冲区
    disp.clear()
    disp.putimage("/ldata/" .. menuBar[1] .. ".bmp", 32, 0, -1)
    disp.putimage("/ldata/" .. menuBar[#menuBar] .. "_small.bmp", 0, 12)
    disp.putimage("/ldata/" .. menuBar[2] .. "_small.bmp", 96, 12)
    disp.puttext("..", 10, 40)
    disp.puttext("..", 107, 40)
    --刷新LCD显示缓冲区到LCD屏幕上
    disp.update()
end

local function leftKey(intid)
    if (intid == cpu.INT_GPIO_NEGEDGE) then
        table.insert(menuBar, table.remove(menuBar, 1))
        displayMenu()
    end
end

local function rightKey(intid)
    if (intid == cpu.INT_GPIO_NEGEDGE) then
        table.insert(menuBar, 1, table.remove(menuBar))
        displayMenu()
    end
end

mono_lcd_spi_ssh1106.init()
displayMenu()
pmd.ldoset(6, pmd.LDO_VIB)
pins.setup(pio.P0_8)
pins.setup(pio.P0_10, leftKey)
pins.setup(pio.P0_11, rightKey)
pins.setup(pio.P0_12)
