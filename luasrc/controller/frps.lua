-- Copyright 2020 lwz322 <lwz322@qq.com>
-- Licensed to the public under the MIT License.

--[[
LuCI 控制器 - frps
该文件为 frps 应用定义了 LuCI 控制器。
它负责处理 HTTP 请求，并定义应用在 LuCI Web 界面中的入口点和菜单结构。
--]]

-- 导入必要的 LuCI 和系统库
local http = require "luci.http"
local uci = require "luci.model.uci".cursor()
local sys = require "luci.sys"

-- 为该控制器定义模块
module("luci.controller.frps", package.seeall)

-- 'index' 函数是该控制器的主要入口点。
-- 它负责在 LuCI Web 界面中构建菜单结构。
function index()
	-- 检查 frps 的配置文件是否存在。
	if not nixio.fs.access("/etc/config/frps") then
		return
	end

	-- 创建一个指向新 CBI 模型的单一主入口点。
	-- 这将显示在 "服务" -> "Frps" 下。
	entry({"admin", "services", "frps"}, cbi("frps"), _("Frps"), 1).dependent = true

	-- 为状态动作创建一个隐藏的入口，用于 AJAX 轮询。
	entry({"admin", "services", "frps", "status"}, call("action_status"))

	-- 为更新状态动作创建一个隐藏的入口
	entry({"admin", "services", "frps", "update_status"}, call("action_update_status"))
end


-- 此函数由 "status" 入口调用。
-- 它检查 frps 进程是否正在运行，并以 JSON 对象的形式返回状态。
function action_status()
	local running = false

	-- 检查自定义的 frps 是否存在，如果存在，则优先检查它的进程
	if nixio.fs.access("/usr/share/frps_custom/frps") then
		running = sys.call("pidof /usr/share/frps_custom/frps >/dev/null") == 0
	else
		-- 否则，检查系统路径的 frps
		running = sys.call("pidof frps >/dev/null") == 0
	end

	-- 准备并发送 JSON 响应
	http.prepare_content("application/json")
	http.write_json({
		running = running
	})
end

-- 新增：用于触发更新脚本的动作
function action_update()
    -- 在后台执行更新脚本
    luci.sys.call("/usr/bin/frps_updater.sh > /tmp/frps_update.log 2>&1 & disown")
    -- 返回一个即时消息
    http.prepare_content("application/json")
    http.write_json({ message = "Update process started in the background. Check log for details." })
end

-- 新增：用于获取更新状态的动作
function action_update_status()
    local logfile = "/tmp/frps_update.log"
    if nixio.fs.access(logfile) then
        local f = io.open(logfile, "r")
        if f then
            local content = f:read("*a")
            f:close()
            http.prepare_content("application/json")
            http.write_json({ status = content })
            return
        end
    end
    http.prepare_content("application/json")
    http.write_json({ status = "No update log found." })
end
