--[[
LuCI - Lua Configuration Interface

Copyright 2016-2017 Caiqinghua <caiqinghua@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

module("luci.controller.admin.cgminerconfiguration", package.seeall)

function index()
	entry({"admin", "network", "cgminer"}, cbi("cgminer/cgminer"), _("CGMiner Configuration"), 90)
end
