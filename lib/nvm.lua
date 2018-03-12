--- 模块功能 ：参数管理
-- @module nvm
-- @author 朱天华
-- @license MIT
-- @copyright openLuat
-- @release 2017.11.9

require"log"

module(...,package.seeall)

package.path = "/?.lua;".."/?.luae;"..package.path

--默认参数配置存储在configname文件中
--实时参数配置存储在paraname文件中
--para：实时参数表
--config：默认参数表
paraname = "/nvm_para.lua"
local para,libdftconfig,configname,econfigname = {}

--- 参数恢复出厂设置
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
函数名：serialize
功能  ：根据不同的数据类型，按照不同的格式，写格式化后的数据到文件中
参数  ：
		pout：文件句柄
		o：数据
返回值：无
]]
local function serialize(pout,o)
	if type(o) == "number" then
		--number类型，直接写原始数据
		pout:write(o)	
	elseif type(o) == "string" then
		--string类型，原始数据左右各加上双引号写入
		pout:write(string.format("%q", o))
	elseif type(o) == "boolean" then
		--boolean类型，转化为string写入
		pout:write(tostring(o))
	elseif type(o) == "table" then
		--table类型，加换行，大括号，中括号，双引号写入
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
函数名：upd
功能  ：更新实时参数表
参数  ：
		overide：是否用默认参数强制更新实时参数
返回值：无
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
函数名：load
功能  ：初始化参数
参数  ：无
返回值：无
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
函数名：save
功能  ：保存参数文件
参数  ：
		s：是否真正保存，true保存，false或者nil不保存
返回值：无
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

--- 设置某个参数的值
-- @param k ，string类型，参数的名字
-- @param v，可以是任意类型，参数的新值
-- @param r，设置原因，只有传入了非nil的有效参数，并且v值和旧值相比发生了改变，才会产生一个PARA_CHANGED_IND消息
-- @param s，是否立即写入到文件系统中，false不写入，其余的都写入
-- @return bool或者nil，成功返回true，失败返回nil
-- @usage nvm.set("name","Luat")，参数name赋值为Luat，立即写入文件系统
-- @usage nvm.set("age",12,"SVR")，参数age赋值为12，立即写入文件系统，如果旧值不是12，会产生一个PARA_CHANGED_IND消息
-- @usage nvm.set("class","Class2",nil,false)，参数class赋值为Class2，不写入文件系统
-- @usage nvm.set("score",{chinese=100,math=99,english=98})，参数score赋值为{chinese=100,math=99,english=98}，立即写入文件系统
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

--- 设置某个参数的值
-- @param k ，string类型，参数的名字
-- @param kk, string类型,参数的值
-- @param v，可以是任意类型，参数的新值
-- @param r，设置原因，只有传入了非nil的有效参数，并且v值和旧值相比发生了改变，才会产生一个PARA_CHANGED_IND消息
-- @param s，是否立即写入到文件系统中，false不写入，其余的都写入
-- @return bool或者nil，成功返回true，失败返回nil
-- @usage nvm.set("name","Luat")，参数name赋值为Luat，立即写入文件系统
-- @usage nvm.set("age",12,"SVR")，参数age赋值为12，立即写入文件系统，如果旧值不是12，会产生一个PARA_CHANGED_IND消息
-- @usage nvm.set("class","Class2",nil,false)，参数class赋值为Class2，不写入文件系统
-- @usage nvm.set("score",{chinese=100,math=99,english=98})，参数score赋值为{chinese=100,math=99,english=98}，立即写入文件系统
function sett(k,kk,v,r,s)
	para[k][kk] = v
	save(s or s==nil)
	if r then sys.publish("TPARA_CHANGED_IND",k,kk,v,r) end
	return true
end

--[[
函数名：flush
功能  ：把参数从内存写到文件中
参数  ：无
返回值：无
]]
function flush()
	save(true)
end

--[[
函数名：get
功能  ：读取参数值
参数  ：
		k：参数名
返回值：参数值
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
函数名：gett
功能  ：读取table类型的参数中的某一项的值
参数  ：
		k：table参数名
		kk：table参数中的键值
返回值：参数值
]]
function gett(k,kk)
	return para[k][kk]
end

--[[
函数名：init
功能  ：初始化参数存储模块
参数  ：
		dftcfgfile：默认配置文件
返回值：无
]]
function init(dftcfgfile)
	local f
	f,libdftconfig = pcall(require,string.match(dftcfgfile,"(.+)%.lua"))
	configname,econfigname = "/lua/"..dftcfgfile,"/lua/"..dftcfgfile.."e"
	--初始化配置文件，从文件中把参数读取到内存中
	load()
end
