--- 模块功能：菜单UI
-- @module menu
-- @author 稀饭放姜
-- @license MIT
-- @copyright openLuat
-- @release 2017.09.30 16:00
module(..., package.seeall)

-- 同屏菜单级数最大值
local SHOW_MAX = 8
-- 同级菜单级数最大值
local ITEMS_MAX = 8

-- 菜单表单
local itemTab = {
    itemId = 1, -- 菜单当前节点
    title = "", -- 菜单标题
    submenu = {} -- 子菜单 or 子条目
    supmenu = {} -- 父菜单 or 父条目
    subFnc = nil -- 节点函数
}

function append(title,supid,fnc)

end
