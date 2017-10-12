--- 模块功能：菜单UI
-- @module ui
-- @author 稀饭放姜
-- @license MIT
-- @copyright openLuat
-- @release 2017.10.12 10:00
module(..., package.seeall)
require "pins"
-- 菜单按键IO列表
local escKey, leftKey, rightKey, enterKey
--- UI初始化方法
-- @param esc, 返回按键PIO
-- @param left, 移动按键PIO
-- @param right,移动按键PIO
-- @param ent,  确定按键PIO
-- @return nothing
-- @usage ui.init(pio.P0_8,pio.P0_10,pio.P0_11,pio.P0_12)
function init(esc, left, right, ent)
    escKey = esc or pio.P0_8
    leftKey = left or pio.P0_10
    rightKey = right or pio.P0_11
    enterKey = ent or pio.P0_12
end
--- 创建UI菜单列表，支持两种风格--图标列表和标题列表
-- @param t, 用户自定义的菜单标题名称或图标的文件名的table
-- @param style,显示风格--false为图标风格,true为标题风格
-- @return table,返回包含标题、子菜单、父菜单、按键动作的table
-- @usage ui.newList(menuBar)
-- @usage ui.newList(menuItem,true)
function newList(t, style)
    -- 根菜单条表
    local self = {titles = t, parent = {}, list = {}}
    -- 附加菜单列表到根菜单条
    self.append = function(title, list)
        self.list[title] = list
        list.parent = self
    end
    -- 显示菜单
    self.display = function()
        disp.clear()
        if style then
            disp.puttext(self.titles[1], 24, 2)
            disp.puttext(" > " .. self.titles[2], 0, 24)
            disp.puttext(self.titles[3], 24, 46)
        else
            disp.putimage("/ldata/" .. self.titles[1] .. ".bmp", 32, 0, -1)
            disp.putimage("/ldata/" .. self.titles[#self.titles] .. "_small.bmp", 0, 12)
            disp.putimage("/ldata/" .. self.titles[2] .. "_small.bmp", 96, 12)
            disp.puttext("..", 10, 40)
            disp.puttext("..", 107, 40)
        end
        disp.update()
        pins.setup(escKey, self.escFun)
        pins.setup(leftKey, self.leftFun)
        pins.setup(rightKey, self.rightFun)
        pins.setup(enterKey, self.enterFun)
    end
    self.escFun = function(intid)
        if intid == cpu.INT_GPIO_NEGEDGE then return end
        if self.parent.enterFun then self.parent.display() end
    end
    self.leftFun = function(intid)
        if intid == cpu.INT_GPIO_NEGEDGE then return end
        table.insert(self.titles, table.remove(self.titles, 1))
        self.display() end
    self.rightFun = function(intid)
        if intid == cpu.INT_GPIO_NEGEDGE then return end
        table.insert(self.titles, 1, table.remove(self.titles))
        self.display() end
    self.enterFun = function(intid)
        if intid == cpu.INT_GPIO_NEGEDGE then return end
        if self.list[self.titles[1]] then self.list[self.titles[1]].display() end
    end
    return self
end
-- 默认按键需要打开电压域
pmd.ldoset(6, pmd.LDO_VIB)