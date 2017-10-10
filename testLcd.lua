module(..., package.seeall)
require "mono_lcd_spi_ssh1106"
require "config"
require "pins"

-- 菜单按键IO列表
local escKey, leftKey, rightKey, enterKey
-- 菜单按键方法列表
local escFun, leftFun, rightFun, enterFun
-- 菜单条的菜单图标列表
local menuBar, menuItems = config.rootMenu, config.menuItems
--LCD分辨率的宽度和高度(单位是像素)
WIDTH, HEIGHT, BPP = disp.getlcdinfo()
--1个ASCII字符宽度为8像素，高度为16像素；汉字宽度和高度都为16像素
CHAR_WIDTH = 8
-- 同屏菜单级数最大值
local SHOW_MAX = 4
-- 同级菜单级数最大值
local ITEMS_MAX = 8

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
function appendMenuBar(fname)
    menuBar = {}
    f = io.open("/ldata/" .. fname .. ".ini")
    for s in f:lines() do table.insert(menuBar, s) end
    f.close()
end
local function displayMenu()
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

function setup(esc, left, right, ent)
    escKey = esc or pio.P0_8
    leftKey = left or pio.P0_10
    rightKey = right or pio.P0_11
    enterKey = ent or pio.P0_12
    
    mono_lcd_spi_ssh1106.init()
    pmd.ldoset(6, pmd.LDO_VIB)
    displayMenu()

    escFun = function(intid)
        return
    end
    leftFun = function(intid)
        if intid == cpu.INT_GPIO_POSEDGE then
            table.insert(menuBar, table.remove(menuBar, 1))
            displayMenu()
        end
    end
    rightFun = function(intid)
        if intid == cpu.INT_GPIO_POSEDGE then
            table.insert(menuBar, 1, table.remove(menuBar))
            displayMenu()
        end
    end
    enterFun = function(intid)
        if intid == cpu.INT_GPIO_POSEDGE then
            local len = #menuItems[menuBar[1]]
            disp.clear()
            if len > SHOW_MAX then len = SHOW_MAX end
            for i = 1, len do
                disp.puttext(menuItems[menuBar[1]][i].title, 24, 16 * i - 16)
            end
            disp.puttext(">> ", 0, 0)
            disp.update()
        end
    end
    pins.setup(escKey, escFun)
    pins.setup(leftKey, leftFun)
    pins.setup(rightKey, rightFun)
    pins.setup(enterKey, enterFun)
end
