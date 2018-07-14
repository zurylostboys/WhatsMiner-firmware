m = Map("pools", translate("Configuration"),
        translate("Please visit <a href='https://microbt.com/support/'> https://microbt.com/support/</a> for support."))

conf = m:section(TypedSection, "pools", "")
conf.anonymous = true
conf.addremove = false

ntp = conf:option(ListValue, "ntp_enable", translate("NTP Service(Default: Global)"))
ntp.default = "global"
ntp:value("global", translate("Global"))
ntp:value("asia", translate("ASIA"))
ntp:value("openwrt", translate("OpenWrt Default"))
ntp:value("disable", translate("Disable"))

ntp_pools = conf:option(Value, "ntp_pools", translate("ntp pools(-p 192.168.1.100)"))

pool1url = conf:option(Value, "pool1url", translate("Pool 1"))
pool1url.datatype = "string"
pool1url:value("stratum+tcp://stratum.f2pool.com:3333")
pool1url:value("stratum+tcp://stratum.haobtc.com:3333")
pool1user = conf:option(Value, "pool1user", translate("Pool1 worker"))
pool1pw = conf:option(Value, "pool1pw", translate("Pool1 password"))
pool2url = conf:option(Value, "pool2url", translate("Pool 2"))
pool2url.datatype = "string"
pool2url:value("stratum+tcp://stratum.f2pool.com:3333")
pool2url:value("stratum+tcp://stratum.haobtc.com:3333")
pool2user = conf:option(Value, "pool2user", translate("Pool2 worker"))
pool2pw = conf:option(Value, "pool2pw", translate("Pool2 password"))
pool3url = conf:option(Value, "pool3url", translate("Pool 3"))
pool3url.datatype = "string"
pool3url:value("stratum+tcp://stratum.f2pool.com:3333")
pool3url:value("stratum+tcp://stratum.haobtc.com:3333")
pool3user = conf:option(Value, "pool3user", translate("Pool3 worker"))
pool3pw = conf:option(Value, "pool3pw", translate("Pool3 password"))

return m
