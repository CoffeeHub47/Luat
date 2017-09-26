--- 模块功能：系统日志记录,分级别日志工具
-- @module log
-- @author 稀饭放姜,wing
-- @license MIT
-- @copyright openLuat
-- @release 2017.09.26
module(...,package.seeall)

local base = _G
local table = require "table"
local rtos = require "rtos"
local uart = require "uart"
local io = require "io"
local os = require "os"
local string = require "string"

-- 加载常用的全局函数至本地
local print = base.print
local unpack = base.unpack
local ipairs = base.ipairs
local type = base.type
local pairs = base.pairs
local assert = base.assert
local tonumber = base.tonumber

--lowPowerFun：用户自定义的“低电关机处理程序”
--lpring：是否已经启动自动关机定时器
local lowPowerFun, lpring
--错误信息文件以及错误信息内容
local LIB_ERR_FILE, libErr, extLibErr = "/lib_err.txt", ""

-- 定义日志级别常量，可在main入口全局指定
-- 例如： LOG_LEVEL=log.LOGLEVEL_WARN
LOG_SILENT           = 0x00;
LOGLEVEL_TRACE       = 0x01;
LOGLEVEL_DEBUG       = 0x02;
LOGLEVEL_INFO        = 0x03;
LOGLEVEL_WARN        = 0x04;
LOGLEVEL_ERROR       = 0x05;
LOGLEVEL_FATAL       = 0x06;

-- 定义日志级别标签，分别对应日志级别的1-6
local LEVEL_TAG = { 'T',  'D', 'I',  'W',  'E', 'F' }

--- 内部函数，支持不同级别的log打印及判断
-- @param level ，日志级别，可选LOGLEVEL_TRACE，LOGLEVEL_DEBUG等
-- @param tag   ，模块或功能名称(标签），作为日志前缀
-- @param ...   ，日志内容，可变参数
-- @return 无
-- @usage _log(LOGLEVEL_TRACE,tag, 'log content')
-- @usage _log(LOGLEVEL_DEBUG,tag, 'log content')
local function _log(level, tag, ...)
  -- INFO 作为默认日志级别
  local OPENLEVEL = base.LOG_LEVEL and base.LOG_LEVEL or LOGLEVEL_INFO
  -- 如果日志级别为静默，或设定级别更高，则不输出日志
  if OPENLEVEL== LOG_SILENT or OPENLEVEL > level then return end
  -- 日志打印输出
  local prefix = string.format("[%s]-[%s]",LEVEL_TAG[level],tag)
  base.print(prefix, ...)

  -- TODO，支持hookup，例如对某级别日志做额外处理
  -- TODO，支持标签过滤
end

--- 输出trace级别的日志
-- @param tag   ，模块或功能名称，作为日志前缀
-- @param ...   ，日志内容，可变参数
-- @return 无
-- @usage trace('moduleA', 'log content')
function trace(tag, ...)
  _log(LOGLEVEL_TRACE,tag,...)
end

--- 输出debug级别的日志
-- @param tag   ，模块或功能名称，作为日志前缀
-- @param ...   ，日志内容，可变参数
-- @return 无
-- @usage debug('moduleA', 'log content')
function debug(tag, ...)
  _log(LOGLEVEL_DEBUG,tag,...)
end

--- 输出info级别的日志
-- @param tag   ，模块或功能名称，作为日志前缀
-- @param ...   ，日志内容，可变参数
-- @return 无
-- @usage info('moduleA', 'log content')
function info(tag, ...)
  _log(LOGLEVEL_INFO,tag,...)
end

--- 输出warn级别的日志
-- @param tag   ，模块或功能名称，作为日志前缀
-- @param ...   ，日志内容，可变参数
-- @return 无
-- @usage warn('moduleA', 'log content')
function warn(tag, ...)
  _log(LOGLEVEL_WARN,tag,...)
end

--- 输出error级别的日志
-- @param tag   ，模块或功能名称，作为日志前缀
-- @param ...   ，日志内容，可变参数
-- @return 无
-- @usage error('moduleA', 'log content')
function error(tag, ...)
  _log(LOGLEVEL_ERROR,tag,...)
end

--- 输出fatal级别的日志
-- @param tag   ，模块或功能名称，作为日志前缀
-- @param ...   ，日志内容，可变参数
-- @return 无
-- @usage fatal('moduleA', 'log content')
function fatal(tag, ...)
  _log(LOGLEVEL_FATAL,tag,...)
end


---检查底层软件版本号和lib脚本需要的最小底层软件版本号是否匹配
-- @return 无
-- @usage log.checkCoreVer()
function checkCoreVer()
    local realver = sys.getCoreVer()
    --如果没有获取到底层软件版本号
    if not realver or realver == "" then
        appendErr("checkCoreVer[no core ver error];")
        return
    end
    
    local buildver = string.match(realver, "Luat_V(%d+)_")
    --如果底层软件版本号格式错误
    if not buildver then
        appendErr("checkCoreVer[core ver format error]" .. realver .. ";")
        return
    end
    
    --lib脚本需要的底层软件版本号大于底层软件的实际版本号
    if tonumber(string.match(sys.CORE_MIN_VER, "Luat_V(%d+)_")) > tonumber(buildver) then
        print("checkCoreVer[core ver match warn]" .. realver .. "," .. sys.CORE_MIN_VER .. ";")
    end
end

--- 获取LIB_ERR_FILE文件中的错误信息，给外部模块使用
-- @return string ,LIB_ERR_FILE文件中的错误信息
-- @usage sys.getExtLibErr()
function getExtLibErr()
    return extLibErr or (readTxt(LIB_ERR_FILE) or "")
end

--- 读取文本文件中的全部内容
-- @string f：文件路径
-- @return string ,文本文件中的全部内容，读取失败为空字符串或者nil
-- @usage log.writeTxt(LIB_ERR_FILE,libErr)
function readTxt(f)
    local file, rt = io.open(f, "r")
    if not file then print("log.readTxt no open -----> ", f) return "" end
    rt = file:read("*a")
    file:close()
    return rt
end

--- 写文本文件
-- @string f：文件路径
-- @string v：要写入的文本内容
-- @return 无
-- @usage log.writeTxt(LIB_ERR_FILE,libErr)
local function writeTxt(f, v)
    local file = io.open(f, "w")
    if not file then print("log.writeTxt no open -----> ", f) return end
    file:write(v)
    file:close()
end


--- 打印LIB_ERR_FILE文件中的错误信息
-- @return 无
-- @usage log.initErr()
function initErr()
    extLibErr = readTxt(LIB_ERR_FILE) or ""
    print("log.initErr -----> ", extLibErr)
    --删除LIB_ERR_FILE文件
    os.remove(LIB_ERR_FILE)
end


--- 追加错误信息到LIB_ERR_FILE文件中
-- @param s：错误信息，用户自定义，一般是string类型，重启后的trace中会打印出此错误信息
-- @return 无
-- @usage log.appendErr("net working timeout!")
function appendErr(s)
    print("log.appendErr -----> ", s)
    libErr = libErr .. s
    writeTxt(LIB_ERR_FILE, libErr)
end
