module(..., package.seeall)
require "mono_lcd_spi_ssh1106"
require "config"
require "pins"

-- 菜单按键IO列表
local escKey, leftKey, rightKey, enterKey
-- 菜单按键方法列表
local escFun, leftFun, rightFun, enterFun
-- 菜单条的菜单图标列表
local menuBar = config.menuBar
-- 菜单条的结构表
--
-- rootMenu.subItem = menuItem
--LCD分辨率的宽度和高度(单位是像素)
WIDTH, HEIGHT, BPP = disp.getlcdinfo()
--1个ASCII字符宽度为8像素，高度为16像素；汉字宽度和高度都为16像素
CHAR_WIDTH = 8
-- 同屏菜单级数最大值
local SHOW_MAX = 4
-- 同级菜单级数最大值
local ITEMS_MAX = 8

-- disp.puttext(" > 德文菜单", 0, 32)
-- 反选
-- disp.setcolor(0x0000)
-- disp.drawrect(0,32,64,32,0xffff)
-- disp.setcolor(0xffff)
function readMenuBar(fname)
    local menuBar = {}
    f = io.open("/ldata/" .. fname .. ".ini")
    for s in f:lines() do table.insert(menuBar, s) end
    f.close()
    return menuBar
end



function setup(esc, left, right, ent)
    escKey = esc or pio.P0_8
    leftKey = left or pio.P0_10
    rightKey = right or pio.P0_11
    enterKey = ent or pio.P0_12
    
    mono_lcd_spi_ssh1106.init()
    pmd.ldoset(6, pmd.LDO_VIB)
    local rootMenu = newBar(config.menuBar)
    local menuItem = newBar(config.menuItem, true)
    rootMenu.append(menuItem)
    rootMenu.display()
    escFun, leftFun, rightFun, enterFun = rootMenu.escFun, rootMenu.leftFun, rootMenu.rightFun, rootMenu.enterFun
    pins.setup(escKey, escFun)
    pins.setup(leftKey, leftFun)
    pins.setup(rightKey, rightFun)
    pins.setup(enterKey, enterFun)
end

function newBar(t, node)
    -- 根菜单条表
    local self = {title = t, list = {}}
    -- 附加菜单列表到根菜单条
    local function append(list)
        self.list = list
    end
    -- 显示根菜单
    local function display()
        disp.clear()
        if node then
            disp.clear()
            disp.puttext(self.title[1], 24, 2)
            disp.puttext(" > " .. self.title[2], 0, 24)
            disp.puttext(self.title[3], 24, 46)
            disp.update()
        else
            disp.putimage("/ldata/" .. self.title[1] .. ".bmp", 32, 0, -1)
            disp.putimage("/ldata/" .. self.title[#self.title] .. "_small.bmp", 0, 12)
            disp.putimage("/ldata/" .. self.title[2] .. "_small.bmp", 96, 12)
            disp.puttext("..", 10, 40)
            disp.puttext("..", 107, 40)
        
        end
        disp.update()
    end
    return {
        display = display,
        append = append,
        escFun = function(intid) return end,
        leftFun = function(intid)
            if intid == cpu.INT_GPIO_NEGEDGE then return end
            
            table.insert(self.title, table.remove(self.title, 1))
            display() end,
        rightFun = function(intid)
            if intid == cpu.INT_GPIO_NEGEDGE then return end
            table.insert(self.title, 1, table.remove(self.title))
            display() end,
        enterFun = function(initid)
            if intid == cpu.INT_GPIO_NEGEDGE then return end
            pins.setup(escKey, self.list.escFun)
            pins.setup(leftKey, self.list.leftFun)
            pins.setup(rightKey, self.list.rightFun)
            pins.setup(enterKey, self.list.enterFun)
            print("self.list.title...name...", self.list.title[1])
            self.list.display()
        end,
    }
end
