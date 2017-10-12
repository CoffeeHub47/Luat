require "mono_lcd_spi_ssh1106"
require "pins"
require "ui"
local newList = ui.newList

local menuBar = {"menu", "set", "message", "alarm", "device", "help", "mange", "test", "user", }
local menuItem = {"menu�˵�2��1", "menu�˵�2��2", "menu�˵�2��3", "menu�˵�2��4", "menu�˵�2��5", "menu�˵�2��6"}
local setItem = {"set�˵�2��1", "set�˵�2��2", "set�˵�2��3", "set�˵�2��4", "set�˵�2��5", "set�˵�2��6"}
local msgItem = {"msg�˵�2��1", "msg�˵�2��2", "msg�˵�2��3", "msg�˵�2��4", "msg�˵�2��5", "msg�˵�2��6"}
local alarmItem = {"alarm�˵�2��1", "alarm�˵�2��2", "alarm�˵�2��3", "alarm�˵�2��4", "alarm�˵�2��5", "alarm�˵�2��6"}
local deviceItem = {"device�˵�2��1", "device�˵�2��2", "device�˵�2��3", "device�˵�2��4", "device�˵�2��5", "device�˵�2��6"}
local helpItem = {"help�˵�2��1", "help�˵�2��2", "help�˵�2��3", "help�˵�2��4", "help�˵�2��5", "help�˵�2��6"}
local mangeItem = {"mange�˵�2��1", "mange�˵�2��2", "mange�˵�2��3", "mange�˵�2��4", "mange�˵�2��5", "mange�˵�2��6"}
local testItem = {"test�˵�2��1", "test�˵�2��2", "test�˵�2��3", "test�˵�2��4", "test�˵�2��5", "test�˵�2��6"}
local userItem = {"user�˵�2��1", "user�˵�2��2", "user�˵�2��3", "user�˵�2��4", "user�˵�2��5", "user�˵�2��6"}

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
