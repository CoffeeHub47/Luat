
module(..., package.seeall)


--���LCD��ʾ������
disp.clear()
--������16,0λ�ÿ�ʼ��ʾ"��ӭʹ��Luat"
-- disp.puttext("-- ���Բ˵� --", 0, 0)
-- disp.puttext("   Ӣ�Ĳ˵�", 0, 16)
-- disp.puttext(" > ���Ĳ˵�", 0, 32)
-- disp.puttext("   ���Ĳ˵�", 0, 48)
--��ʾlogoͼƬ
-- disp.setcolor(0x0000)
-- disp.drawrect(0,32,64,32,0xffff)
-- disp.setcolor(0xffff)
disp.putimage("/ldata/msg.bmp",32,0,-1)
disp.putimage("/ldata/device_small.bmp",0,12)
disp.putimage("/ldata/menu_small.bmp",96,12)

-- disp.putimage("/ldata/2.bmp",64,0,-1)
-- disp.putimage("/ldata/up.bmp",56,16)
disp.puttext("..", 10, 40)
disp.puttext("..", 107, 40)
--ˢ��LCD��ʾ��������LCD��Ļ��
disp.update()
