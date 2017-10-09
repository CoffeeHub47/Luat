--- 模块功能：菜单UI
-- @module menu
-- @author 稀饭放姜
-- @license MIT
-- @copyright openLuat
-- @release 2017.09.30 16:00
module(..., package.seeall)

--LCD分辨率的宽度和高度(单位是像素)
WIDTH,HEIGHT,BPP = disp.getlcdinfo()
--1个ASCII字符宽度为8像素，高度为16像素；汉字宽度和高度都为16像素
CHAR_WIDTH = 8
-- 同屏菜单级数最大值
local SHOW_MAX = 4
-- 同级菜单级数最大值
local ITEMS_MAX = 8

-- 菜单表单
local itemTab = {
    itemId = 1, -- 菜单当前节点
    subFnc = nil, -- 节点函数
    title = {}, -- 同级菜单标题
    supmenu = {}, -- 父菜单 or 父条目
    submenu = {}, -- 子菜单 or 子条目
}

function append(title, supid, fnc)

end

function displayMenu()

end
