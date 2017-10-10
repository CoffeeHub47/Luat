module(..., package.seeall)

menuItems = {}
rootMenu = {"menu", "set", "message", "alarm", "device", "help", "mange", "test", "user", }
for i = 1, #rootMenu do
    menuItems[rootMenu[i]] = {}
end

function addItem(tab, ...)
    -- 菜单表单
    local itemTab = {
        title = "", -- 同级菜单标题
        escFun = nil,
        leftFun = nil,
        rightFun = nil,
        enterFun = nil,
        subItem = {},
    }
    itemTab.title = arg[1]
    itemTab.escFun = arg[2]
    itemTab.leftFun = arg[3]
    itemTab.rightFun = arg[4]
    itemTab.enterFun = arg[5]
    itemTab.subItem = arg[6]
    table.insert(tab, itemTab)
end
addItem(menuItems[rootMenu[1]], "中文菜单1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[1]], "英文菜单2", "escFun2", "leftFun2", "rightFun2", "enterFun2")
addItem(menuItems[rootMenu[2]], "设置菜单1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[2]], "设置菜单2", "escFun2", "leftFun2", "rightFun2", "enterFun2")
addItem(menuItems[rootMenu[3]], "信息菜单1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[3]], "信息菜单2", "escFun2", "leftFun2", "rightFun2", "enterFun2")
addItem(menuItems[rootMenu[4]], "警报菜单1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[4]], "警报菜单2", "escFun2", "leftFun2", "rightFun2", "enterFun2")
addItem(menuItems[rootMenu[5]], "设备菜单1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[5]], "设备菜单2", "escFun2", "leftFun2", "rightFun2", "enterFun2")
addItem(menuItems[rootMenu[6]], "帮助菜单1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[6]], "帮助菜单2", "escFun2", "leftFun2", "rightFun2", "enterFun2")
addItem(menuItems[rootMenu[7]], "管理菜单1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[7]], "管理菜单2", "escFun2", "leftFun2", "rightFun2", "enterFun2")
addItem(menuItems[rootMenu[8]], "测试菜单1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[8]], "测试菜单2", "escFun2", "leftFun2", "rightFun2", "enterFun2")
addItem(menuItems[rootMenu[9]], "测试菜单1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[9]], "测试菜单2", "escFun2", "leftFun2", "rightFun2", "enterFun2")