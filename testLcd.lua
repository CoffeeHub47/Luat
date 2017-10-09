
module(..., package.seeall)


--清空LCD显示缓冲区
disp.clear()
--从坐标16,0位置开始显示"欢迎使用Luat"
-- disp.puttext("-- 语言菜单 --", 0, 0)
-- disp.puttext("   英文菜单", 0, 16)
-- disp.puttext(" > 德文菜单", 0, 32)
-- disp.puttext("   日文菜单", 0, 48)
--显示logo图片
-- disp.setcolor(0x0000)
-- disp.drawrect(0,32,64,32,0xffff)
-- disp.setcolor(0xffff)
disp.putimage("/ldata/1.bmp",0,0,-1)
disp.putimage("/ldata/2.bmp",64,0,-1)
disp.putimage("/ldata/up.bmp",56,16)
-- disp.puttext("▼", 60, 32)
-- disp.puttext("V", 60, 40)
--刷新LCD显示缓冲区到LCD屏幕上
disp.update()
