
module(..., package.seeall)


--���LCD��ʾ������
disp.clear()
--������16,0λ�ÿ�ʼ��ʾ"��ӭʹ��Luat"
disp.puttext("1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ��", 0, 0)
-- disp.puttext("abcdefghijklmnop", 0, 16)
-- disp.puttext("ABCDEFGHIJKLMNOP", 0, 32)
-- disp.puttext("~!@#$%^&*()_+{}|", 0, 48)
--��ʾlogoͼƬ
--disp.putimage("/ldata/logo_"..(lcd.BPP==1 and "mono.bmp" or "color.png"),lcd.BPP==1 and 41 or 1,lcd.BPP==1 and 18 or 33)
--ˢ��LCD��ʾ��������LCD��Ļ��
disp.update()
