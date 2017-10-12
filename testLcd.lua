--- 模块功能：菜单UI
-- @module menu
-- @author 稀饭放姜
-- @license MIT
-- @copyright openLuat
-- @release 2017.10.12 10:00
module(..., package.seeall)
require "mono_lcd_spi_ssh1106"
require "pins"
require "ui"
require "config"
local newList = ui.newList

mono_lcd_spi_ssh1106.init()
ui.init()

local rootMenu = newList(config.menuBar)
local menuItem = newList(config.menuItem, true)
local setItem = newList(config.setItem, true)
local msgItem = newList(config.msgItem, true)
local alarmItem = newList(config.alarmItem, true)
local deviceItem = newList(config.deviceItem, true)
local helpItem = newList(config.helpItem, true)
local mangeItem = newList(config.mangeItem, true)
local testItem = newList(config.testItem, true)
local userItem = newList(config.userItem, true)

rootMenu.append(config.menuBar[1], menuItem)
rootMenu.append(config.menuBar[2], setItem)
rootMenu.append(config.menuBar[3], msgItem)
rootMenu.append(config.menuBar[4], alarmItem)
rootMenu.append(config.menuBar[5], deviceItem)
rootMenu.append(config.menuBar[6], helpItem)
rootMenu.append(config.menuBar[7], mangeItem)
rootMenu.append(config.menuBar[8], testItem)
rootMenu.append(config.menuBar[9], userItem)
rootMenu.display()
