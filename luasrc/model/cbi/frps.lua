--[[
LuCI CBI Model - frps Unified Settings
This file defines the new, simplified web interface for frps settings.
It provides a single enable/disable switch and a large textarea for the TOML configuration.
--]]

-- 创建 Map 对象
-- 第一个参数是 UCI 配置文件的名称, "frps"
-- 第二个参数是页面的标题
m = Map("frps", "%s - %s" % { translate("Frps"), translate("Settings") },
"<p>%s</p><p>%s</p>" % {
	translate("Frp is a fast reverse proxy to help you expose a local server behind a NAT or firewall to the internet."),
	translatef("For more information, please visit: %s",
		"<a href=\"https://github.com/fatedier/frp\" target=\"_blank\">https://github.com/fatedier/frp</a>")
})

-- 附加状态显示视图
m:append(Template("frps/status_header"))

-- 获取 "main" 配置节
s = m:section(NamedSection, "main", "frps")
s.addremove = false
s.anonymous = true

-- 添加启用/禁用开关
o = s:option(Flag, "enabled", translate("Enable Frps"))
o.rmempty = false

-- 添加 TOML 配置文本框
o = s:option(TextValue, "toml_config", translate("TOML Configuration"))
o.rows = 20
o.wrap = "off"
o.description = translate("Enter the full content of your frps.toml file here.")

-- 创建一个新的部分用于 frps 版本管理
s2 = m:section(TypedSection, "frps_updater", translate("Frps Version Management"))
s2.anonymous = true
s2.addremove = false

-- 显示当前由插件管理的 frps 版本
o = s2:option(DummyValue, "custom_version", translate("Managed Frps Version"))
o.uci_option = "main.custom_version"

-- 更新按钮
o = s2:option(Button, "_update", translate("Check and Update Frps"))
o.inputstyle = "apply"
o.description = translate("Click to download the latest version of frps from GitHub.")

-- 用于显示更新状态的区域
o.write = function(self, section, value)
    self.super.write(self, section, value)
    luci.http.write('<div id="update_status" style="margin-top:10px;"></div>')
end

o.onclick = function(self, section)
    // 显示“正在更新”消息
    var updateStatusElm = document.getElementById('update_status');
    updateStatusElm.innerHTML = '<em>Checking for updates...</em>';

    // 禁用按钮以防止重复点击
    var updateButton = document.querySelector('input[name="cbi.button._update"]');
    updateButton.disabled = true;

    // 开始轮询更新状态
    var poll_count = 0;
    var poll_interval = setInterval(function() {
        XHR.get('<%=luci.dispatcher.build_url("admin/services/frps/update_status")%>', null, function(x, data) {
            if (x.status === 200 && data && data.status) {
                // 将日志内容显示在状态区域
                updateStatusElm.innerHTML = '<pre>' + data.status + '</pre>';
                // 如果日志包含“successful”或“Error”，则停止轮询
                if (data.status.includes('successful') || data.status.includes('Error')) {
                    clearInterval(poll_interval);
                    updateButton.disabled = false; // 重新启用按钮
                }
            }
            poll_count++;
            // 如果轮询超过 2 分钟，则停止
            if (poll_count > 24) {
                clearInterval(poll_interval);
                updateStatusElm.innerHTML += '<br><em>Update check timed out.</em>';
                updateButton.disabled = false; // 重新启用按钮
            }
        });
    }, 5000); // 每 5 秒轮询一次

    // 触发更新脚本
    XHR.get('<%=luci.dispatcher.build_url("admin/services/frps/update")%>');

    return false;
end

return m
