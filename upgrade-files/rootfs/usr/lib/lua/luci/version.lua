local io     = require "io"
local os     = require "os"
local string = require "string"
local table  = require "table"
local fs     = require "nixio.fs"
local util = require "luci.util"

local tonumber, pcall, dofile, _G = tonumber, pcall, dofile, _G

module "luci.version"

if pcall(dofile, "/etc/openwrt_release") and _G.DISTRIB_DESCRIPTION then
	distname    = ""
	distversion = _G.DISTRIB_DESCRIPTION
	if _G.DISTRIB_REVISION then
		distrevision = _G.DISTRIB_REVISION
		if not distversion:find(distrevision,1,true) then
			distversion = distversion .. " " .. distrevision
		end
	end
else
	distname    = "OpenWrt"
	distversion = "Development Snapshot"
end

luciname    = "LuCI Master"
luciversion = "git-16.336.70424-1fd43b4"

-- Detect miner version info

if pcall(dofile, "/etc/microbt_release") then
	if _G.MINER_NAME then
		minername = _G.MINER_NAME
	else
		minername = "unknown"
	end
	if _G.FIRMWARE_VERSION then
		firmwareversion = _G.FIRMWARE_VERSION
	else
		firmwareversion = "unknown"
	end
else
	minername = "unknown"
	firmwareversion = "unknown"
end

local version = util.exec("/usr/bin/cgminer-api -o version")
cgminerversion = version:match(".*,CGMiner=(.+),.*")

if cgminerversion == nil then
	cgminerversion = "unknown(waiting cgminer to start)"
end

os.execute("/usr/bin/lua-detect-version")

if pcall(dofile, "/tmp/lua-version") then
	if _G.MODEL_NAME then
		modelname = _G.MODEL_NAME
	else
		modelname = "unknown"
	end
	if _G.CONTROL_BOARD_TYPE then
		controlboardtype = _G.CONTROL_BOARD_TYPE
	else
		controlboardtype = "CB-unknown"
	end
	if _G.HASH_BOARD_TYPE then
		hashboardtype = _G.HASH_BOARD_TYPE
	else
		hashboardtype = "HB-unknown"
	end
	if _G.POWER_TYPE then
		powertype = _G.POWER_TYPE
	else
		powertype = "PX"
	end
	if _G.PCB_DATA then
		pcbdata = "-" .. _G.PCB_DATA
	else
		pcbdata = ""
	end
else
	modelname = "unknown"
	controlboardtype = "CB-unknown"
	hashboardtype = "HB-unknown"
    powertype = "PX"
end

minermodel = minername .. " " .. modelname
hardwareversion = modelname .. "." .. hashboardtype .. "." .. controlboardtype .. "." .. powertype .. pcbdata
