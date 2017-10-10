module(..., package.seeall)

menuItems = {}
rootMenu = {"menu", "set", "message", "alarm", "device", "help", "mange", "test", "user", }
for i = 1, #rootMenu do
    menuItems[rootMenu[i]] = {}
end

function addItem(tab, ...)
    -- �˵���
    local itemTab = {
        title = "", -- ͬ���˵�����
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
addItem(menuItems[rootMenu[1]], "���Ĳ˵�1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[1]], "Ӣ�Ĳ˵�2", "escFun2", "leftFun2", "rightFun2", "enterFun2")
addItem(menuItems[rootMenu[2]], "���ò˵�1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[2]], "���ò˵�2", "escFun2", "leftFun2", "rightFun2", "enterFun2")
addItem(menuItems[rootMenu[3]], "��Ϣ�˵�1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[3]], "��Ϣ�˵�2", "escFun2", "leftFun2", "rightFun2", "enterFun2")
addItem(menuItems[rootMenu[4]], "�����˵�1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[4]], "�����˵�2", "escFun2", "leftFun2", "rightFun2", "enterFun2")
addItem(menuItems[rootMenu[5]], "�豸�˵�1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[5]], "�豸�˵�2", "escFun2", "leftFun2", "rightFun2", "enterFun2")
addItem(menuItems[rootMenu[6]], "�����˵�1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[6]], "�����˵�2", "escFun2", "leftFun2", "rightFun2", "enterFun2")
addItem(menuItems[rootMenu[7]], "����˵�1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[7]], "����˵�2", "escFun2", "leftFun2", "rightFun2", "enterFun2")
addItem(menuItems[rootMenu[8]], "���Բ˵�1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[8]], "���Բ˵�2", "escFun2", "leftFun2", "rightFun2", "enterFun2")
addItem(menuItems[rootMenu[9]], "���Բ˵�1", "escFun1", "leftFun1", "rightFun1", "enterFun1")
addItem(menuItems[rootMenu[9]], "���Բ˵�2", "escFun2", "leftFun2", "rightFun2", "enterFun2")