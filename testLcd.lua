
module(..., package.seeall)


--清空LCD显示缓冲区
disp.clear()
--从坐标16,0位置开始显示"欢迎使用Luat"
disp.puttext("1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ中", 0, 0)
-- disp.puttext("abcdefghijklmnop", 0, 16)
-- disp.puttext("ABCDEFGHIJKLMNOP", 0, 32)
-- disp.puttext("~!@#$%^&*()_+{}|", 0, 48)
--显示logo图片
--disp.putimage("/ldata/logo_"..(lcd.BPP==1 and "mono.bmp" or "color.png"),lcd.BPP==1 and 41 or 1,lcd.BPP==1 and 18 or 33)
--刷新LCD显示缓冲区到LCD屏幕上
disp.update()
