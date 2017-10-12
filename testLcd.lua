require "mono_lcd_spi_ssh1106"
require "pins"
require "ui"
local newList = ui.newList

local menuBar = {"menu", "set", "message", "alarm", "device", "help", "mange", "test", "user", }
local menuItem = {"menu菜单2级1", "menu菜单2级2", "menu菜单2级3", "menu菜单2级4", "menu菜单2级5", "menu菜单2级6"}
local setItem = {"set菜单2级1", "set菜单2级2", "set菜单2级3", "set菜单2级4", "set菜单2级5", "set菜单2级6"}
local msgItem = {"msg菜单2级1", "msg菜单2级2", "msg菜单2级3", "msg菜单2级4", "msg菜单2级5", "msg菜单2级6"}
local alarmItem = {"alarm菜单2级1", "alarm菜单2级2", "alarm菜单2级3", "alarm菜单2级4", "alarm菜单2级5", "alarm菜单2级6"}
local deviceItem = {"device菜单2级1", "device菜单2级2", "device菜单2级3", "device菜单2级4", "device菜单2级5", "device菜单2级6"}
local helpItem = {"help菜单2级1", "help菜单2级2", "help菜单2级3", "help菜单2级4", "help菜单2级5", "help菜单2级6"}
local mangeItem = {"mange菜单2级1", "mange菜单2级2", "mange菜单2级3", "mange菜单2级4", "mange菜单2级5", "mange菜单2级6"}
local testItem = {"test菜单2级1", "test菜单2级2", "test菜单2级3", "test菜单2级4", "test菜单2级5", "test菜单2级6"}
local userItem = {"user菜单2级1", "user菜单2级2", "user菜单2级3", "user菜单2级4", "user菜单2级5", "user菜单2级6"}

local rootMenu = newList(menuBar)
local menuItem = newList(menuItem, true)
local setItem = newList(setItem, true)
local msgItem = newList(msgItem, true)
local alarmItem = newList(alarmItem, true)
local deviceItem = newList(deviceItem, true)
local helpItem = newList(helpItem, true)
local mangeItem = newList(mangeItem, true)
local testItem = newList(testItem, true)
local userItem = newList(userItem, true)

rootMenu.append(menuBar[1], menuItem)
rootMenu.append(menuBar[2], setItem)
rootMenu.append(menuBar[3], msgItem)
rootMenu.append(menuBar[4], alarmItem)
rootMenu.append(menuBar[5], deviceItem)
rootMenu.append(menuBar[6], helpItem)
rootMenu.append(menuBar[7], mangeItem)
rootMenu.append(menuBar[8], testItem)
rootMenu.append(menuBar[9], userItem)

mono_lcd_spi_ssh1106.init()
ui.init()
rootMenu.display()
