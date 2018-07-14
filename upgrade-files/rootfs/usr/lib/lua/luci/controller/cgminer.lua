--[[
LuCI - Lua Configuration Interface

Copyright 2016-2017 Caiqinghua <caiqinghua@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

module("luci.controller.cgminer", package.seeall)

function index()
	entry({"admin", "status", "cgminerstatus"}, cbi("cgminer/cgminerstatus"), _("CGMiner Status"), 1)
	entry({"admin", "status", "cgminerapi"}, call("action_cgminerapi"), _("CGMiner API Log"), 2)
	entry({"admin", "status", "cgminerstatus", "restart"}, call("action_cgminerrestart"), nil).leaf = true
	entry({"admin", "status", "checkupgrade"}, call("action_checkupgrade"), nil).leaf = true
	entry({"admin", "status", "set_miningmode"}, call("action_setminingmode"), nil).leaf = true
	entry({"admin", "status", "cgminerdebug"}, call("action_cgminerdebug"), nil).leaf = true
end

function action_cgminerrestart()
	luci.util.exec("/etc/init.d/cgminer restart")
	luci.http.redirect(
	luci.dispatcher.build_url("admin", "status", "cgminerstatus")
	)
end

function action_cgminerapi()
	local pp   = io.popen("/usr/bin/cgminer-api stats|sed 's/ =>/:/g'|sed 's/\\] /\\]\\n    /g'|sed 's/:/ =>/g'")
	local data = pp:read("*a")
	pp:close()

	luci.template.render("cgminerapi", {api=data})
end

function num_commas(n)
	return tostring(math.floor(n)):reverse():gsub("(%d%d%d)","%1,"):gsub(",(%-?)$","%1"):reverse()
end

function valuetodate(elapsed)
	if elapsed then
		local str
		local days
		local h
		local m
		local s = elapsed % 60;
		elapsed = elapsed - s
		elapsed = elapsed / 60
		if elapsed == 0 then
			str = string.format("%ds", s)
		else
			m = elapsed % 60;
			elapsed = elapsed - m
			elapsed = elapsed / 60
			if elapsed == 0 then
				str = string.format("%dm %ds", m, s);
			else
				h = elapsed % 24;
				elapsed = elapsed - h
				elapsed = elapsed / 24
				if elapsed == 0 then
					str = string.format("%dh %dm %ds", h, m, s)
				else
					str = string.format("%dd %dh %dm %ds", elapsed, h, m, s);
				end
			end
		end
		return str
	end

	return "date invalid"
end

function summary()
	local data = {}
	local summary = luci.util.execi("/usr/bin/cgminer-api -o summary | sed \"s/|/\\n/g\" ")

	if not summary then
		return
	end

	for line in summary do
		local elapsed, mhsav, foundblocks, getworks, accepted,
		rejected, hw, utility, stale, getfailures,
		remotefailures, networkblocks, totalmh,
		diffaccepted, diffrejected, diffstale, bestshare, 
		temp,
		freq_max, freq_min, freq_avg,
		fanspeedin, fanspeedout, fan_stop_count, fan_stop_turn_off_time_threshold, fan_stop_turn_off_times =
		line:match(".*," ..
			"Elapsed=(-?%d+)," ..
			"MHS av=(-?[%d%.]+)," ..
			".*," ..
			"Found Blocks=(-?%d+)," ..
			"Getworks=(-?%d+)," ..
			"Accepted=(-?%d+)," ..
			"Rejected=(-?%d+)," ..
			"Hardware Errors=(-?%d+)," ..
			"Utility=([-?%d%.]+)," ..
			".*," ..
			"Stale=(-?%d+)," ..
			"Get Failures=(-?%d+)," ..
			".-" ..
			"Remote Failures=(-?%d+)," ..
			"Network Blocks=(-?%d+)," ..
			"Total MH=(-?[%d%.]+)," ..
			".-" ..
			"Difficulty Accepted=(-?[%d]+)%.%d+," ..
			"Difficulty Rejected=(-?[%d]+)%.%d+," ..
			"Difficulty Stale=(-?[%d]+)%.%d+," ..
			"Best Share=(-?%d+)," ..
			"Temperature=(-?[%d]+).%d+," ..
			"freq_max=(-?%d+)," ..
			"freq_min=(-?%d+)," ..
			"freq_avg=(-?%d+)," ..
			"Fan Speed In=(-?%d+)," ..
			"Fan Speed Out=(-?%d+)," ..
			"fan_stop_count=(-?%d+)," ..
			"fan_stop_turnoff_threshold=(-?%d+)," ..
			"fan_stop_turnoff_times=(-?%d+),")
		if elapsed then
			data[#data+1] = {
				['elapsed'] = valuetodate(elapsed),
				['mhsav'] = num_commas(mhsav),
				['foundblocks'] = foundblocks,
				['getworks'] = num_commas(getworks),
				['accepted'] = num_commas(accepted),
				['rejected'] = num_commas(rejected),
				['hw'] = num_commas(hw),
				['utility'] = num_commas(utility),
				['stale'] = stale,
				['getfailures'] = getfailures,
				['remotefailures'] = remotefailures,
				['networkblocks'] = networkblocks,
				['totalmh'] = string.format("%e",totalmh),
				['diffaccepted'] = num_commas(diffaccepted),
				['diffrejected'] = num_commas(diffrejected),
				['diffstale'] = diffstale,
				['bestshare'] = num_commas(bestshare),
				['fanspeedin'] = num_commas(fanspeedin),
				['fanspeedout'] = num_commas(fanspeedout)
			}
		end
	end

	return data
end

function pools()
	local data = {}
	local pools = luci.util.execi("/usr/bin/cgminer-api -o pools | sed \"s/|/\\n/g\" ")

	if not pools then
		return
	end

	for line in pools do
		local pi, url, st, pri, quo, lp, gw, a, r, sta, gf,
		rf, user, lst, ds, da, dr, dsta, lsd, hs, sa, sd, hg =
		line:match("POOL=(-?%d+)," ..
			"URL=(.*)," ..
			"Status=(%a+)," ..
			"Priority=(-?%d+)," ..
			"Quota=(-?%d+)," ..
			"Long Poll=(%a+)," ..
			"Getworks=(-?%d+)," ..
			"Accepted=(-?%d+)," ..
			"Rejected=(-?%d+)," ..
			".*," ..
			"Stale=(-?%d+)," ..
			"Get Failures=(-?%d+)," ..
			"Remote Failures=(-?%d+)," ..
			"User=(.*)," ..
			"Last Share Time=(-?%d+)," ..
			"Diff1 Shares=(-?%d+)," ..
			".*," ..
			"Difficulty Accepted=(-?%d+)[%.%d]+," ..
			"Difficulty Rejected=(-?%d+)[%.%d]+," ..
			"Difficulty Stale=(-?%d+)[%.%d]+," ..
			"Last Share Difficulty=(-?%d+)[%.%d]+," ..
			".-," ..
			"Has Stratum=(%a+)," ..
			"Stratum Active=(%a+)," ..
			".-," ..
			"Stratum Difficulty=(-?%d+)[%.%d]+," ..
			"Has GBT=(%a+)")
		if pi then
			if lst == "0" then
				lst_date = "Never"
			else
				lst_date = os.date("%c", lst)
			end
			data[#data+1] = {
				['pool'] = pi,
				['url'] = url,
				['status'] = st,
				['priority'] = pri,
				['quota'] = quo,
				['longpoll'] = lp,
				['getworks'] = gw,
				['accepted'] = a,
				['rejected'] = r,
				['stale'] = sta,
				['getfailures'] = gf,
				['remotefailures'] = rf,
				['user'] = user,
				['lastsharetime'] = lst_date,
				['diff1shares'] = ds,
				['diffaccepted'] = da,
				['diffrejected'] = dr,
				['diffstale'] = dsta,
				['lastsharedifficulty'] = lsd,
				['hasstratum'] = hs,
				['stratumactive'] = sa,
				['stratumdifficulty'] = sd,
				['hasgbt'] = hg
			}
		end
	end

	return data
end

function devs()
	local data = {}
	local devs = luci.util.execi("/usr/bin/cgminer-api -o edevs | sed \"s/|/\\n/g\" ")

	if not devs then
		return
	end

	for line in devs do
		local asc, name, id, slot, enabled, status, temp, freq, fanspeedin, fanspeedout, mhsav, mhs5s, mhs1m, mhs5m, mhs15m, lvw, dh =
		line:match("ASC=(%d+)," ..
			"Name=([%a%d]+)," ..
			"ID=(%d+)," ..
			"Slot=(%d+)," ..
			"Enabled=(%a+)," ..
			"Status=(%a+)," ..
			"Temperature=(-?[%d]+).%d+," ..
			"Chip Frequency=(%d+)," ..
			"Fan Speed In=(%d+)," ..
			"Fan Speed Out=(%d+)," ..
			"MHS av=(-?[%.%d]+)," ..
			"MHS 5s=(-?[%.%d]+)," ..
			"MHS 1m=(-?[%.%d]+)," ..
			"MHS 5m=(-?[%.%d]+)," ..
			"MHS 15m=(-?[%.%d]+)," ..
			".*," ..
			"Last Valid Work=(-?%d+)," ..
			"Device Hardware%%=(-?[%.%d]+)")

		if lvw == "0" then
			lvw_date = "Never"
		else
			lvw_date = os.date("%c", lst)
		end

		if asc then
			data[#data+1] = {
				['name'] = name .. slot,
				['enable'] = enabled,
				['status'] = status,
				['temp'] = temp,
				['mhsav'] = mhsav,
				['mhs5s'] = mhs5s,
				['mhs1m'] = mhs1m,
				['mhs5m'] = mhs5m,
				['mhs15m'] = mhs15m,
				['lvw'] = lvw_date
			}
		end
	end

	return data
end

function stats()
	local ver = require "luci.version"
	local data = {}
	local stats = luci.util.execi("/usr/bin/cgminer-api -o estats | sed \"s/|/\\n/g\" ")

	if not stats then
		return
	end

	for line in stats do
		if ver.modelname == "M0" then
			local sta, id, elapsed, slot, freqs_avg, temp_in, temp_out, effective_chips, upfreq_complete =
			line:match("STATS=(%d+)," ..
				"ID=([%a%d]+)," ..
				"Elapsed=(%d+)," ..
				".*," ..
				"slot=(%d+)," ..
				".*," ..
				"freqs_avg=(%d+)," ..
				".*," ..
				"temp_1=(-?[%.%d]+)," ..
				".*," ..
				"temp_5=(-?[%.%d]+)," ..
				".*," ..
				"chip_model_effective_count=(%d+)," ..
				".*," ..
				"upfreq_complete=(%d+)," ..
				".*,")

			if sta then
				data[#data+1] = {
					['id'] = "SM" .. slot,
					['elapsed'] = valuetodate(elapsed),
					['slot'] = slot,
					['freqs_avg'] = freqs_avg,
					['temp_1'] = temp_out,
					['temp_2'] = temp_in,
					['effective_chips'] = effective_chips,
					['upfreq_complete'] = upfreq_complete
				}
			end
		else
			local sta, id, elapsed, slot, freqs_avg, temp_out, temp_in, effective_chips, upfreq_complete =
			line:match("STATS=(%d+)," ..
				"ID=([%a%d]+)," ..
				"Elapsed=(%d+)," ..
				".*," ..
				"slot=(%d+)," ..
				".*," ..
				"freqs_avg=(%d+)," ..
				".*," ..
				"temp_1=(-?[%.%d]+)," ..
				"temp_2=(-?[%.%d]+)," ..
				".*," ..
				"chip_model_effective_count=(%d+)," ..
				".*," ..
				"upfreq_complete=(%d+)," ..
				".*,")

			if sta then
				data[#data+1] = {
					['id'] = "SM" .. slot,
					['elapsed'] = valuetodate(elapsed),
					['slot'] = slot,
					['freqs_avg'] = freqs_avg,
					['temp_1'] = temp_out,
					['temp_2'] = temp_in,
					['effective_chips'] = effective_chips,
					['upfreq_complete'] = upfreq_complete
				}
			end
		end
	end

	return data
end

function events()
	local data = {}
	local count
	local lastline

	local f1 = io.open("/root/.events/event-reboot-control-board")
	local f2 = io.open("/root/.events/event-reset-hash-board")
	local f3 = io.open("/root/.events/event-restart-cgminer")
	local f4 = io.open("/root/.events/event-zero-hash-rate")
	local f5 = io.open("/tmp/event-auto-adjust-voltage")

	if f1 then
		count = 0
		for line in f1:lines() do
        		count = count + 1
 	       		lastline = line
		end

		local r1 = {}

		for a in string.gmatch(lastline, "([^|]+)") do
    			table.insert(r1, a)
		end

		data[#data+1] = {
			['lasttime'] = r1[1],
			['id'] = r1[2],
			['action'] = r1[3],
			['source'] = r1[4],
			['cause'] = r1[5],
			['times'] = tostring(count) 
		}

		io.close(f1)
	end

	if f2 then
		count = 0
		for line in f2:lines() do
        		count = count + 1
 	       		lastline = line
		end

		local r2 = {}

		for a in string.gmatch(lastline, "([^|]+)") do
    			table.insert(r2, a)
		end

		data[#data+1] = {
			['lasttime'] = r2[1],
			['id'] = r2[2],
			['action'] = r2[3],
			['source'] = r2[4],
			['cause'] = r2[5],
			['times'] = tostring(count)
		}

		io.close(f2)
	end

	if f3 then
		count = 0
		for line in f3:lines() do
        		count = count + 1
 	       		lastline = line
		end

		local r3 = {}

		for a in string.gmatch(lastline, "([^|]+)") do
    			table.insert(r3, a)
		end

		data[#data+1] = {
			['lasttime'] = r3[1],
			['id'] = r3[2],
			['action'] = r3[3],
			['source'] = r3[4],
			['cause'] = r3[5],
			['times'] = tostring(count)
		}

		io.close(f3)
	end

	if f4 then
		count = 0
		for line in f4:lines() do
        		count = count + 1
 	       		lastline = line
		end

		local r4 = {}

		for a in string.gmatch(lastline, "([^|]+)") do
    			table.insert(r4, a)
		end

		data[#data+1] = {
			['lasttime'] = r4[1],
			['id'] = r4[2],
			['action'] = r4[3],
			['source'] = r4[4],
			['cause'] = r4[5],
			['times'] = tostring(count)
		}

		io.close(f4)
	end

	if f5 then
		count = 0
		for line in f5:lines() do
        		count = count + 1
 	       		lastline = line
		end

		local r5 = {}

		for a in string.gmatch(lastline, "([^|]+)") do
    			table.insert(r5, a)
		end

		data[#data+1] = {
			['lasttime'] = r5[1],
			['id'] = r5[2],
			['action'] = r5[3],
			['source'] = r5[4],
			['cause'] = r5[5],
			['times'] = tostring(count)
		}

		io.close(f5)
	end

	return data
end

function action_setminingmode()
	local uci = luci.model.uci.cursor()
	local mmode = luci.http.formvalue("mining_mode")
	local modetab = {
			customs = " ",
			normal = "-c /etc/config/a4.normal",
			eco = "-c /etc/config/a4.eco",
			turbo = "-c /etc/config/a4.turbo"
			}

	if modetab[mmode] then
		uci:set("cgminer", "default", "mining_mode", modetab[mmode])
		uci:save("cgminer")
		uci:commit("cgminer")
		if mmode == "customs" then
			luci.http.redirect(
			luci.dispatcher.build_url("admin", "status", "cgminer")
			)
		else
			action_cgminerrestart()
		end
	end
end

function action_mmupgrade()
	local mm_tmp   = "/tmp/mm.mcs"
	local finish_flag   = "/tmp/mm_finish"

	local function mm_upgrade_avail()
		if nixio.fs.access("/usr/bin/mm-tools") then
			return true
		end

		return nil
	end

	local function mm_supported()
		local mm_tmp   = "/tmp/mm.mcs"

		if not nixio.fs.access(mm_tmp) then
			return false
		end

		local filesize = nixio.fs.stat(mm_tmp).size

		-- TODO: Check mm.mcs format
		if filesize == 0 then
			return false
		end
		return true
	end

	local function mm_checksum()
		return (luci.sys.exec("md5sum %q" % mm_tmp):match("^([^%s]+)"))
	end

	local function storage_size()
		local size = 0
		if nixio.fs.access("/proc/mtd") then
			for l in io.lines("/proc/mtd") do
				local d, s, e, n = l:match('^([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+"([^%s]+)"')
				if n == "linux" or n == "firmware" then
					size = tonumber(s, 16)
					break
				end
			end
		elseif nixio.fs.access("/proc/partitions") then
			for l in io.lines("/proc/partitions") do
				local x, y, b, n = l:match('^%s*(%d+)%s+(%d+)%s+([^%s]+)%s+([^%s]+)')
				if b and n and not n:match('[0-9]') then
					size = tonumber(b) * 1024
					break
				end
			end
		end
		return size
	end

	local fp
	luci.http.setfilehandler(
		function(meta, chunk, eof)
			if not fp then
				if meta and meta.name == "image" then
					fp = io.open(mm_tmp, "w")
				end
			end
			if chunk then
				fp:write(chunk)
			end
			if eof and fp then
				fp:close()
			end
		end
	)

	if luci.http.formvalue("image") or luci.http.formvalue("step") then
		--
		-- Check firmware
		--
		local step = tonumber(luci.http.formvalue("step") or 1)
		if step == 1 then
			if mm_supported() == true then
				luci.template.render("mmupgrade", {
					checksum = mm_checksum(),
					storage  = storage_size(),
					size     = nixio.fs.stat(mm_tmp).size,
				})
			else
				nixio.fs.unlink(mm_tmp)
				luci.template.render("mmupload", {
					mm_upgrade_avail = mm_upgrade_avail(),
					mm_image_invalid = true
				})
			end
		--
		--  Upgrade firmware
		--
		elseif step == 2 then
			luci.template.render("mmapply")
			fork_exec("mmupgrade;touch %q;" %{ finish_flag })
		elseif step == 3 then
			nixio.fs.unlink(finish_flag)
			luci.template.render("mmapply", {
					finish = 1
				})
		end
	else
		luci.template.render("mmupload", {
			mm_upgrade_avail = mm_upgrade_avail()
		})
	end
end

function action_checkupgrade()
	local status = {}
	local finish_flag   = "/tmp/mm_finish"

	if not nixio.fs.access(finish_flag) then
		status.finish = 0
	else
		status.finish = 1
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end

function fork_exec(command)
	local pid = nixio.fork()
	if pid > 0 then
		return
	elseif pid == 0 then
		-- change to root dir
		nixio.chdir("/")

		-- patch stdin, out, err to /dev/null
		local null = nixio.open("/dev/null", "w+")
		if null then
			nixio.dup(null, nixio.stderr)
			nixio.dup(null, nixio.stdout)
			nixio.dup(null, nixio.stdin)
			if null:fileno() > 2 then
				null:close()
			end
		end

		-- replace with target command
		nixio.exec("/bin/sh", "-c", command)
	end
end

function action_cgminerdebug()
	luci.util.exec("cgminer-api \"debug|D\"")
	luci.http.redirect(
	luci.dispatcher.build_url("admin", "status", "cgminerapi")
	)
end
