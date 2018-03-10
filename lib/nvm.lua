--- ģ�鹦�ܣ���������
-- @module nvm
-- @author ���컪
-- @license MIT
-- @copyright openLuat
-- @release 2017.11.9

require"log"

module(...,package.seeall)

package.path = "/?.lua;".."/?.luae;"..package.path

--Ĭ�ϲ������ô洢��configname�ļ���
--ʵʱ�������ô洢��paraname�ļ���
--para��ʵʱ������
--config��Ĭ�ϲ�����
paraname = "/nvm_para.lua"
local para,libdftconfig,configname,econfigname = {}

--- �����ָ���������
-- @return nil
-- @usage nvm.restore()
function restore()
	local fpara,fconfig = io.open(paraname,"wb"),io.open(configname,"rb")
	if not fconfig then fconfig = io.open(econfigname,"rb") end
	fpara:write(fconfig:read("*a"))
	fpara:close()
	fconfig:close()
	upd(true)
end

--[[
��������serialize
����  �����ݲ�ͬ���������ͣ����ղ�ͬ�ĸ�ʽ��д��ʽ��������ݵ��ļ���
����  ��
		pout���ļ����
		o������
����ֵ����
]]
local function serialize(pout,o)
	if type(o) == "number" then
		--number���ͣ�ֱ��дԭʼ����
		pout:write(o)	
	elseif type(o) == "string" then
		--string���ͣ�ԭʼ�������Ҹ�����˫����д��
		pout:write(string.format("%q", o))
	elseif type(o) == "boolean" then
		--boolean���ͣ�ת��Ϊstringд��
		pout:write(tostring(o))
	elseif type(o) == "table" then
		--table���ͣ��ӻ��У������ţ������ţ�˫����д��
		pout:write("{\n")
		for k,v in pairs(o) do
			if type(k) == "number" then
				pout:write(" [" .. k .. "] = ")
			elseif type(k) == "string" then
				pout:write(" [\"" .. k .."\"] = ")
			else
				error("cannot serialize table key " .. type(o))
			end
			serialize(pout,v)
			pout:write(",\n")
		end
		pout:write("}\n")
	else
		error("cannot serialize a " .. type(o))
	end
end

--[[
��������upd
����  ������ʵʱ������
����  ��
		overide���Ƿ���Ĭ�ϲ���ǿ�Ƹ���ʵʱ����
����ֵ����
]]
function upd(overide)
	for k,v in pairs(libdftconfig) do
		if k ~= "_M" and k ~= "_NAME" and k ~= "_PACKAGE" then
			if overide or para[k] == nil then
				para[k] = v
			end			
		end
	end
end

--[[
��������load
����  ����ʼ������
����  ����
����ֵ����
]]
local function load()
	local f = io.open(paraname,"rb")
	if not f or f:read("*a") == "" then
		if f then f:close() end
		restore()
		return
	end
	f:close()
	
	f,para = pcall(require,string.match(paraname,"/(.+)%.lua"))
	if not f then
		para = {}
		restore()
		return
	end
	upd()
end

--[[
��������save
����  ����������ļ�
����  ��
		s���Ƿ��������棬true���棬false����nil������
����ֵ����
]]
local function save(s)
	if not s then return end
	local f = {}
	f.write = function(self, s) table.insert(self, s) end

	f:write("module(...)\n")

	for k,v in pairs(para) do
		if k ~= "_M" and k ~= "_NAME" and k ~= "_PACKAGE" then
			f:write(k .. " = ")
			serialize(f,v)
			f:write("\n")
		end
	end

	local fpara = io.open(paraname, 'wb')
	fpara:write(table.concat(f))
	fpara:close()
end

--- ����ĳ��������ֵ
-- @param k ��string���ͣ�����������
-- @param v���������������ͣ���������ֵ
-- @param r������ԭ��ֻ�д����˷�nil����Ч����������vֵ�;�ֵ��ȷ����˸ı䣬�Ż����һ��PARA_CHANGED_IND��Ϣ
-- @param s���Ƿ�����д�뵽�ļ�ϵͳ�У�false��д�룬����Ķ�д��
-- @return bool����nil���ɹ�����true��ʧ�ܷ���nil
-- @usage nvm.set("name","Luat")������name��ֵΪLuat������д���ļ�ϵͳ
-- @usage nvm.set("age",12,"SVR")������age��ֵΪ12������д���ļ�ϵͳ�������ֵ����12�������һ��PARA_CHANGED_IND��Ϣ
-- @usage nvm.set("class","Class2",nil,false)������class��ֵΪClass2����д���ļ�ϵͳ
-- @usage nvm.set("score",{chinese=100,math=99,english=98})������score��ֵΪ{chinese=100,math=99,english=98}������д���ļ�ϵͳ
function set(k,v,r,s)
	local bchg = true
	if type(v) ~= "table" then
		bchg = (para[k] ~= v)
	end
	log.info("nvm.set",bchg,k,v,r,s)
	if bchg then		
		para[k] = v
		save(s or s==nil)
		if r then sys.publish("PARA_CHANGED_IND",k,v,r) end
	end
	return true
end

--- ����ĳ��������ֵ
-- @param k ��string���ͣ�����������
-- @param kk, string����,������ֵ
-- @param v���������������ͣ���������ֵ
-- @param r������ԭ��ֻ�д����˷�nil����Ч����������vֵ�;�ֵ��ȷ����˸ı䣬�Ż����һ��PARA_CHANGED_IND��Ϣ
-- @param s���Ƿ�����д�뵽�ļ�ϵͳ�У�false��д�룬����Ķ�д��
-- @return bool����nil���ɹ�����true��ʧ�ܷ���nil
-- @usage nvm.set("name","Luat")������name��ֵΪLuat������д���ļ�ϵͳ
-- @usage nvm.set("age",12,"SVR")������age��ֵΪ12������д���ļ�ϵͳ�������ֵ����12�������һ��PARA_CHANGED_IND��Ϣ
-- @usage nvm.set("class","Class2",nil,false)������class��ֵΪClass2����д���ļ�ϵͳ
-- @usage nvm.set("score",{chinese=100,math=99,english=98})������score��ֵΪ{chinese=100,math=99,english=98}������д���ļ�ϵͳ
function sett(k,kk,v,r,s)
	para[k][kk] = v
	save(s or s==nil)
	if r then sys.publish("TPARA_CHANGED_IND",k,kk,v,r) end
	return true
end

--[[
��������flush
����  ���Ѳ������ڴ�д���ļ���
����  ����
����ֵ����
]]
function flush()
	save(true)
end

--[[
��������get
����  ����ȡ����ֵ
����  ��
		k��������
����ֵ������ֵ
]]
function get(k)
	if type(para[k]) == "table" then
		local tmp = {}
		for kk,v in pairs(para[k]) do
			tmp[kk] = v
		end
		return tmp
	else
		return para[k]
	end
end

--[[
��������gett
����  ����ȡtable���͵Ĳ����е�ĳһ���ֵ
����  ��
		k��table������
		kk��table�����еļ�ֵ
����ֵ������ֵ
]]
function gett(k,kk)
	return para[k][kk]
end

--[[
��������init
����  ����ʼ�������洢ģ��
����  ��
		dftcfgfile��Ĭ�������ļ�
����ֵ����
]]
function init(dftcfgfile)
	local f
	f,libdftconfig = pcall(require,string.match(dftcfgfile,"(.+)%.lua"))
	configname,econfigname = "/lua/"..dftcfgfile,"/lua/"..dftcfgfile.."e"
	--��ʼ�������ļ������ļ��аѲ�����ȡ���ڴ���
	load()
end
