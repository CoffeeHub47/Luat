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

function readMenuBar(fname)
    local menuBar = {}
    f = io.open("/ldata/" .. fname .. ".ini")
    for s in f:lines() do table.insert(menuBar, s) end
    f.close()
    return menuBar
end

function init(esc, left, right, ent)
    mono_lcd_spi_ssh1106.init()
    pmd.ldoset(6, pmd.LDO_VIB)
    local rootMenu = newList(config.menuBar)
    local menuItem = newList(config.menuItem, true)
    rootMenu.append(menuItem)
    rootMenu.display()
    escFun, leftFun, rightFun, enterFun = rootMenu.escFun, rootMenu.leftFun, rootMenu.rightFun, rootMenu.enterFun
    setup(esc, left, right, ent)
end

function setup(esc, left, right, ent)
    escKey = esc or pio.P0_8
    leftKey = left or pio.P0_10
    rightKey = right or pio.P0_11
    enterKey = ent or pio.P0_12
    pins.setup(escKey, escFun)
    pins.setup(leftKey, leftFun)
    pins.setup(rightKey, rightFun)
    pins.setup(enterKey, enterFun)
end

function newList(t, node)
    -- 根菜单条表
    local self = {title = t, parent = {}, list = {}}
    -- 附加菜单列表到根菜单条
    self.append = function(list)
        self.list = list
        list.parent = self
    end
    -- 显示菜单
    self.display = function()
        disp.clear()
        if node then
            disp.puttext(self.title[1], 24, 2)
            disp.puttext(" > " .. self.title[2], 0, 24)
            disp.puttext(self.title[3], 24, 46)
        else
            disp.putimage("/ldata/" .. self.title[1] .. ".bmp", 32, 0, -1)
            disp.putimage("/ldata/" .. self.title[#self.title] .. "_small.bmp", 0, 12)
            disp.putimage("/ldata/" .. self.title[2] .. "_small.bmp", 96, 12)
            disp.puttext("..", 10, 40)
            disp.puttext("..", 107, 40)
        end
        disp.update()
    end
    self.escFun = function(intid)
        if intid == cpu.INT_GPIO_NEGEDGE then return end
        if self.parent.enterFun then
            self.parent.display()
            escFun, leftFun, rightFun, enterFun = self.parent.escFun, self.parent.leftFun, self.parent.rightFun, self.parent.enterFun
            setup()
        end
    end
    self.leftFun = function(intid)
        if intid == cpu.INT_GPIO_NEGEDGE then return end
        table.insert(self.title, table.remove(self.title, 1))
        self.display() end
    self.rightFun = function(intid)
        if intid == cpu.INT_GPIO_NEGEDGE then return end
        table.insert(self.title, 1, table.remove(self.title))
        self.display() end
    self.enterFun = function(intid)
        if intid == cpu.INT_GPIO_NEGEDGE then return end
        if self.list.enterFun then
            self.list.display()
            escFun, leftFun, rightFun, enterFun = self.list.escFun, self.list.leftFun, self.list.rightFun, self.list.enterFun
            setup()
        end
    end
    return self
end
