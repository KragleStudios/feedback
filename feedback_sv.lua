util.AddNetworkString("fw_feedback_new")
util.AddNetworkString("fw_feedback_getcount")
util.AddNetworkString("fw_feedback_get")

fw.feedback.createTable = function()
	if sql.TableExists("fw_feedback") then return end
	sql.Query("CREATE TABLE fw_feedback (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, content TEXT, user_id TEXT, user_name TEXT, time INTEGER);")
end
fw.feedback.createTable()

fw.feedback.addReport = function(content, user_id, user_name)
	user_id = user_id and sql.SQLStr(user_id) or "'SERVER'"
	user_name = user_name and sql.SQLStr(user_name) or "'SERVER'"
	content = sql.SQLStr(content)

	sql.Query("INSERT INTO fw_feedback (type, content, user_id, user_name, time) VALUES ('report', " .. content .. ", " .. user_id .. ", " .. user_name .. ", " .. os.time() .. ");")
end

fw.feedback.addIdea = function(content, user_id, user_name)
	user_id = user_id and sql.SQLStr(user_id) or "'SERVER'"
	user_name = user_name and sql.SQLStr(user_name) or "'SERVER'"
	content = sql.SQLStr(content)

	sql.Query("INSERT INTO fw_feedback (type, content, user_id, user_name, time) VALUES ('idea', " .. content .. ", " .. user_id .. ", " .. user_name .. ", " .. os.time() .. ");")
end

fw.feedback.getReports = function(count, start)
	local sqlCode = "SELECT * FROM fw_feedback WHERE type = 'report';"

	if start or count then
		sqlCode = "SELECT * FROM fw_feedback WHERE type = 'report' LIMIT " .. (start and (start .. ", " .. count) or count).. ";"
	end

	return sql.Query(sqlCode) or {}
end

fw.feedback.getIdeas = function(count, start)
	local sqlCode = "SELECT * FROM fw_feedback WHERE type = 'idea';"

	if start or count then
		sqlCode = "SELECT * FROM fw_feedback WHERE type = 'idea' LIMIT " .. (start and (start .. ", " .. count) or count).. ";"
	end

	return sql.Query(sqlCode) or {}
end

fw.feedback.getAll = function()
	return sql.Query("SELECT * FROM fw_feedback;") or {}
end

net.Receive("fw_feedback_new", function(_, ply)
	if ply.fw_last_feedback and ply.fw_last_feedback + fw.feedback.cooldown > CurTime() then return end

	local ftype, text = net.ReadString(), net.ReadString()
	if not ftype or not text or #text < 15 then return end

	if ftype == "idea" then
		fw.feedback.addIdea(text, ply:SteamID64(), ply:Nick())
	else
		fw.feedback.addReport(text, ply:SteamID64(), ply:Nick())
	end

	ply:FWChatPrint("Thank you for giving us your feedback! We really appreciate it.")

	ply.fw_last_feedback = CurTime()
end)

net.Receive("fw_feedback_getcount", function(_, ply)
	if not ply:IsSuperAdmin() then return end

	local count = tonumber(sql.QueryValue("SELECT COUNT(*) FROM fw_feedback WHERE type = " .. sql.SQLStr(net.ReadString()) .. ";")) or 1
	if count <= 0 then count = 1 end
	local pages = math.ceil(count / 12)
	net.Start("fw_feedback_getcount")
	net.WriteFloat(pages)
	net.Send(ply)
end)

net.Receive("fw_feedback_get", function(_, ply)
	if not ply:IsSuperAdmin() then return end

	local ftype, page = net.ReadString(), net.ReadFloat()
	local data = (ftype == "idea" and fw.feedback.getIdeas or fw.feedback.getReports)(12, (page - 1) * 12)

	net.Start("fw_feedback_get")
	net.WriteTable(data)
	net.Send(ply)
end) 