fw.feedback.menuButton = KEY_F8
fw.feedback.lastTime = -fw.feedback.cooldown

fw.feedback.send = function(ftype, text)
	if fw.feedback.lastTime + fw.feedback.cooldown > CurTime() then 
		return "You have to wait " .. math.ceil(fw.feedback.lastTime + fw.feedback.cooldown - CurTime()) .. " second(s) before sending another report." 
	elseif #text < 15 then
		return "You have to give us more information about your problem/idea."
	end

	net.Start("fw_feedback_new")
	net.WriteString(ftype)
	net.WriteString(text)
	net.SendToServer()

	fw.feedback.lastTime = CurTime()

	return false
end

local frame
fw.feedback.openInfo = function(data)
	local w, h = 600, 500
	frame = vgui.Create("FWUIFrame")
	frame:SetSize(w, h)
	frame:SetTitle((data.type == "idea" and "Idea" or "Report") .. " by " .. data.user_name)
	frame:MakePopup()
	frame:Center()

	local text = vgui.Create("RichText", frame)
	text:SetSize(w - 10, h - 30)
	text:SetPos(5, 25)
	text:SetFontInternal(fw.fonts.default:atSize(18))
	text.addText = function(self, text, color)
		color = color or color_white
		self:InsertColorChange(color.r, color.g, color.b, color.a or 255)
		self:AppendText(text)
	end

	text:addText("Username: ", Color(126, 87, 194))
	text:addText(data.user_name .. "\n")
	text:addText("SteamID: ", Color(126, 87, 194))
	text:addText(data.user_id .. "\n")
	text:addText("Time: ", Color(126, 87, 194))
	text:addText(os.date("%H:%M:%S - %d/%m/%Y", data.time) .. "\n\n\n")

	text:addText(data.content)
end
 
local frame
fw.feedback.openReports = function()
	local w, h = 800, 600
	local ftype
	local curPage = 1
	local curType = "idea"

	frame = vgui.Create("FWUIFrame")
	frame:SetSize(w, h)
	frame:SetTitle("Feedback")
	frame:MakePopup()
	frame:Center()
	frame.Load = function(self, type, page, bypass)
		if page == curPage and not bypass then return end

		ftype:SetDisabled(true)

		curType = type
		curPage = page

		net.Start("fw_feedback_get")
		net.WriteString(type)
		net.WriteFloat(page)
		net.SendToServer()
	end

	local contentpnl = vgui.Create("FWUIPanel", frame)
	contentpnl:SetSize(w - 10, h - 100)
	contentpnl:SetPos(5, 55)
	contentpnl.Clear = function(self)
		for k, v in pairs(self:GetChildren()) do
			if IsValid(v) then
				v:Remove()
			end
		end
	end

	local lineSize = (contentpnl:GetTall() - 13 * 5) / 12
	net.Receive("fw_feedback_get", function()
		if !IsValid(contentpnl) then return end

		ftype:SetDisabled(false)
		contentpnl:Clear()

		local data = net.ReadTable()
		local pos = 5
		local font = fw.fonts.default:atSize(lineSize - 20)
		for k, v in pairs(data) do
			local l = vgui.Create("FWUIPanel", contentpnl)
			l:SetPos(5, pos)
			l:SetSize(contentpnl:GetWide() - 10, lineSize)

			local text = vgui.Create("DLabel", l)
			text:SetFont(font)
			text:SetText(v.user_name .. ": " .. string.Explode("\n", v.content)[1])
			text:SetX(10)
			text:SetTall(lineSize - 20)
			text:CenterVertical()
			text:SetWide(contentpnl:GetWide() - 110)

			local view = vgui.Create("FWUIButton", l)
			view:SetSize(80, lineSize - 10)
			view:SetPos(l:GetWide() - 85, 5)
			view:SetText("View")
			view.DoClick = function()
				fw.feedback.openInfo(v)
			end

			pos = pos + lineSize + 5
		end
	end)
	
	ftype = vgui.Create("DComboBox", frame)
	ftype:SetSize(w - 10, 25)
	ftype:SetPos(5, 25)
	ftype:AddChoice("Ideas", "idea")
	ftype:AddChoice("Reports", "report")
	ftype:ChooseOptionID(1)
	ftype:SetDisabled(true)
	ftype.OnSelect = function(_, _, _, ftype)
		net.Start("fw_feedback_getcount")
		net.WriteString(ftype)
		net.SendToServer()
		frame:Load(ftype, 1, true)
	end

	local footer = vgui.Create("FWUIPanel", frame)
	footer:SetSize(w - 10, 35)
	footer:SetPos(5, h - 40)

	net.Start("fw_feedback_getcount")
	net.WriteString(curType)
	net.SendToServer()

	frame:Load(curType, 1, true)

	net.Receive("fw_feedback_getcount", function()
		if not IsValid(footer) then return end
		
		for k, v in pairs(footer:GetChildren()) do
			if IsValid(v) then
				v:Remove()
			end
		end

		local pages = math.max(net.ReadFloat(), 1)
		local compact = pages > 10
		local xpos = 30

		local pagination = vgui.Create("DPanel", footer)
		pagination:SetSize(w, 25)
		pagination:SetPos(0, 5)
		pagination.Paint = function() end

		local prev = vgui.Create("FWUIButton", pagination)
		prev:SetSize(25, 25)
		prev:SetText("<")
		prev.DoClick = function()
			frame:Load(curType, math.max(curPage - 1, 1))
		end

		for i = 1, pages do
			if compact then
				if i == 6 then
					local pb = vgui.Create("FWUIButton", pagination)
					pb:SetSize(25, 25)
					pb:SetPos(xpos, 0)
					pb:SetText("...")
					pb.OnMousePressed = function() end
					pb.IsHovered = function() return false end
					xpos = xpos + 30
					continue
				elseif i > 6 and i < pages - 5 then
					continue
				end
			end
			local pb = vgui.Create("FWUIButton", pagination)
			pb:SetSize(25, 25)
			pb:SetPos(xpos, 0)
			pb:SetText(i)
			local oldPaintOver = pb.PaintOver
			pb.PaintOver = function(self, w, h)
				oldPaintOver(self, w, h)
				if curPage ~= i then return end
				surface.SetDrawColor(0, 255, 0, 20)
				surface.DrawOutlinedRect(0, 0, w, h)
				surface.DrawOutlinedRect(1, 1, w - 2, h - 2)
			end
			pb.DoClick = function()
				frame:Load(curType, i)
			end
			xpos = xpos + 30
		end

		local nextp = vgui.Create("FWUIButton", pagination)
		nextp:SetSize(25, 25)
		nextp:SetText(">")
		nextp:SetPos(xpos, 0)
		nextp.DoClick = function()
			frame:Load(curType, math.min(curPage + 1, pages))
		end
		xpos = xpos + 25

		pagination:SetWide(xpos)
		pagination:CenterHorizontal()
	end)
end

local frame 
fw.feedback.openMenu = function()
	if IsValid(frame) then frame:SetVisible(true) return end

	local w, h = 450, 300
	local viewBtn

	frame = vgui.Create("FWUIFrame")
	frame:SetSize(w, h)
	frame:SetTitle("Feedback")
	frame:MakePopup()
	frame:Center()
	frame.OnRemove = function()
		if IsValid(viewBtn) then
			viewBtn:Remove()
		end
	end

	local ftype = vgui.Create("DComboBox", frame)
	ftype:SetSize(w - 10, 25)
	ftype:SetPos(5, 25)

	ftype:AddChoice("Report a problem", "report")
	ftype:AddChoice("Propose an idea", "idea")
	ftype:ChooseOptionID(1)

	local text = vgui.Create("DTextEntry", frame)
	text:SetSize(w - 10, h - 90)
	text:SetPos(5, 55)
	text:SetMultiline(true)

	local submit = vgui.Create("FWUIButton", frame)
	submit:SetPos(5, h - 30)
	submit:SetSize(w - 10, 25)
	submit:SetText("Submit")
	submit.DoClick = function()
		local err = fw.feedback.send(ftype:GetOptionData(ftype:GetSelectedID()), text:GetValue() or "")
		if err then 
			chat.AddText(Color(55, 55, 55), "[" .. GAMEMODE.CondensedName .. "] ", color_white, err)
		else
			frame:Remove()
		end
	end

	if LocalPlayer():IsSuperAdmin() then
		local x, y = frame:GetPos()
		viewBtn = vgui.Create("FWUIButton")
		viewBtn:SetSize(w, 25)
		viewBtn:SetPos(x, y - 30)
		viewBtn:SetText("View Reports")
		viewBtn.DoClick = function()
			fw.feedback.openReports()
			frame:Remove()
		end
	end
end

fw.hook.Add("Think", "feedback_menuopen", function()
	if input.IsKeyDown(fw.feedback.menuButton) then
		fw.feedback.openMenu()
	end
end)