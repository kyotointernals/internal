if not LPH_OBFUSCATED then
	local dummy = function(...) return ... end
	LPH_NO_VIRTUALIZE = LPH_NO_VIRTUALIZE or dummy
	LPH_NO_UPVALUES = LPH_NO_UPVALUES or dummy
	LPH_OBFUSCATED = LPH_OBFUSCATED or false
	LPH_JIT_MAX = LPH_JIT_MAX or dummy
	LPH_ENCFUNC = LPH_ENCFUNC or dummy
	LPH_ENCSTR = LPH_ENCSTR or dummy
	LPH_ENCNUM = LPH_ENCNUM or dummy
	LPH_CRASH = LPH_CRASH or dummy
	LPH_JIT = LPH_JIT or dummy
end

local req = request or http_request or syn.request

function missing(t, f, fallback)
	if type(f) == t then return f end
	return fallback
end

local function xorBytes(a, b)
    local result = table.create(#a)
    for i = 1, #a do
        result[i] = string.char(bit32.bxor(string.byte(a, i), string.byte(b, i)))
    end
    return table.concat(result)
end

local function padKey(key, blockSize)
    if #key > blockSize then
        key = crypt.hash(key, "sha256")
    end
    if #key < blockSize then
        key = key .. string.rep("\0", blockSize - #key)
    end
    return key
end

local function hmac_sha256(key, data)
    local blockSize = 64

    key = padKey(key, blockSize)

    local o_key_pad = xorBytes(key, string.rep(string.char(0x5c), blockSize))
    local i_key_pad = xorBytes(key, string.rep(string.char(0x36), blockSize))

    local inner = crypt.hash(i_key_pad .. data, "sha256")
    return crypt.hash(o_key_pad .. inner, "sha256")
end

hmac = missing("function", crypt.hmac, newcclosure(function(key, data, algo)
	return hmac_sha256(key, data) --- I don't need full crypt.hmac hashing libraries, I only use sha256 and this is a shitsploit patch anywho so who cares
end))
local sm
if isfile and isfile("savemanager.lua") then
	sm = loadstring(readfile("savemanager.lua"))()
else
	sm = loadstring(readfile("savemanager.lua"))()
end
local GameName = game.PlaceId

sm:SetFolder("kyoto/games/" .. tostring(GameName))
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local accent_color = Color3.fromRGB(91, 134, 198)
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local userid_str = tostring(lp.UserId)
local key = crypt.generatekey()
local mac = hmac(key, userid_str, "sha256")

local P = Instance.new("ScreenGui")
P.Name = mac
P.Parent = game:GetService("CoreGui")
P.OnTopOfCoreBlur = true
P.DisplayOrder = 0x7fffffff
P.IgnoreGuiInset = true
P.ResetOnSpawn = false
P.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local IndicatorContainer = Instance.new("Frame")
IndicatorContainer.Size = UDim2.new(0, 158, 1, 0)
IndicatorContainer.BorderColor3 = Color3.new(0, 0, 0)
IndicatorContainer.BackgroundTransparency = 1
IndicatorContainer.BorderSizePixel = 0
IndicatorContainer.BackgroundColor3 = Color3.new(1, 1, 1)
IndicatorContainer.Parent = P

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Name = "UIListLayout"
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
UIListLayout.Parent = IndicatorContainer

pcall(function()
	P.ScreenInsets = Enum.ScreenInsets.None
end)

pcall(function()
	P.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
end)

pcall(function()
	P.ClipToDeviceSafeArea = false
end)

local function extractArg(first, second, selfObj)
	if second ~= nil then
		return second
	end
	if first == selfObj then
		return nil
	end
	return first
end

local Library = {}

function Library:CreateWindow(name)
	local internal = {
		Tabs = {},
		ActiveTab = nil,
		Items = {}
	}

	local globalLibraryItems = internal.Items
	local window = {}
	window.Items = globalLibraryItems
	window.SaveManager = sm
	local window_mt = {}

	window_mt.__index = function(self, key)
		if internal[key] ~= nil then
			return internal[key]
		end
		return rawget(window, key)
	end

	window_mt.__newindex = function(self, key, value)
		if internal[key] ~= nil then
			internal[key] = value
		else
			rawset(self, key, value)
		end
	end

	setmetatable(window, window_mt)


	local Camera = workspace.CurrentCamera

	local function getViewport()
		if Camera and Camera.ViewportSize.X > 100 and Camera.ViewportSize.Y > 100 then
			return Camera.ViewportSize
		end
		if P.AbsoluteSize.X > 100 and P.AbsoluteSize.Y > 100 then
			return P.AbsoluteSize
		end
		return Vector2.new(800, 600)
	end

	local function calculateWindowSize()
		local vp = getViewport()
		local defaultW = 617
		local defaultH = 572

		-- On mobile / smaller screens, adapt height and width proportionally so the UI scales cleanly
		local marginY = 28
		local marginX = 24
		local targetH = math.min(defaultH, math.max(240, math.floor(vp.Y - marginY)))

		-- Scale width proportionally with height to maintain the designed aspect ratio
		local scaleRatio = targetH / defaultH
		local targetW = math.min(defaultW, math.max(350, math.floor(defaultW * scaleRatio)))
		targetW = math.min(targetW, math.max(300, math.floor(vp.X - marginX)))

		return targetW, targetH
	end

	local initW, initH = calculateWindowSize()

	local Main = Instance.new("Frame")
	Main.Name = "Main"
	Main.Active = true
	Main.AnchorPoint = Vector2.new(0.5, 0.5)
	Main.Size = UDim2.new(0, initW, 0, initH)
	Main.BorderColor3 = Color3.new(0, 0, 0)
	Main.BorderSizePixel = 0
	Main.Position = UDim2.new(0.5, 0, 0.5, 0)
	Main.BackgroundColor3 = Color3.fromRGB(14,14,14)
	Main.Parent = P

	local MainSizeConstraint = Instance.new("UISizeConstraint")
	MainSizeConstraint.MinSize = Vector2.new(initW, initH)
	MainSizeConstraint.MaxSize = Vector2.new(initW, initH)
	MainSizeConstraint.Parent = Main

	local function updateWindowSize()
		local targetW, targetH = calculateWindowSize()
		Main.Size = UDim2.new(0, targetW, 0, targetH)
		if MainSizeConstraint then
			MainSizeConstraint.MinSize = Vector2.new(targetW, targetH)
			MainSizeConstraint.MaxSize = Vector2.new(targetW, targetH)
		end
	end

	if Camera then
		Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateWindowSize)
	end
	P:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateWindowSize)
	task.defer(updateWindowSize)
	task.delay(0.2, updateWindowSize)

	local Ui_Scale = Instance.new("UIScale")
	Ui_Scale.Parent = Main
	Ui_Scale.Scale = 1
	window.Scale = Ui_Scale

	local Frame = Instance.new("Frame")
	Frame.Name = "Frame"
	Frame.Size = UDim2.new(1, 0, 0, 26)
	Frame.BorderColor3 = Color3.new(0, 0, 0)
	Frame.BorderSizePixel = 0
	Frame.BackgroundColor3 = Color3.new(0.08, 0.08, 0.08)
	Frame.Parent = Main

	local Frame_2 = Instance.new("Frame")
	Frame_2.Name = "Frame"
	Frame_2.Size = UDim2.new(1, 0, 0, 2)
	Frame_2.BorderColor3 = Color3.new(0, 0, 0)
	Frame_2.BorderSizePixel = 0
	Frame_2.Position = UDim2.new(0, 0, 1, 0)
	Frame_2.BackgroundColor3 = accent_color
	Frame_2.Parent = Frame

	local TextLabel = Instance.new("TextLabel")
	TextLabel.Name = "TextLabel"
	TextLabel.Size = UDim2.new(0, 110, 0, 26)
	TextLabel.BorderColor3 = Color3.new(0, 0, 0)
	TextLabel.BorderSizePixel = 0
	TextLabel.BackgroundTransparency = 1
	TextLabel.Position = UDim2.new(0, 8, 0, 0)
	TextLabel.BackgroundColor3 = Color3.new(1, 1, 1)
	TextLabel.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	TextLabel.TextColor3 = Color3.new(0.92, 0.92, 0.92)
	TextLabel.Text = name
	TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	TextLabel.Parent = Frame

	local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	UITextSizeConstraint.Name = "UITextSizeConstraint"
	UITextSizeConstraint.MinTextSize = 14
	UITextSizeConstraint.Parent = TextLabel

	local Frame_3 = Instance.new("ScrollingFrame")
	Frame_3.Name = "Frame"
	Frame_3.Size = UDim2.new(1, -120, 0, 26)
	Frame_3.BorderColor3 = Color3.new(0, 0, 0)
	Frame_3.BorderSizePixel = 0
	Frame_3.BackgroundTransparency = 1
	Frame_3.Position = UDim2.new(0, 115, 0, 0)
	Frame_3.BackgroundColor3 = Color3.new(1, 1, 1)
	Frame_3.ScrollBarThickness = 0
	Frame_3.ScrollingDirection = Enum.ScrollingDirection.X
	Frame_3.AutomaticCanvasSize = Enum.AutomaticSize.X
	Frame_3.CanvasSize = UDim2.new(0, 0, 0, 0)
	Frame_3.Parent = Frame

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Name = "UIListLayout"
	UIListLayout.Parent = Frame_3
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0,0)

	local UIStroke = Instance.new("UIStroke")
	UIStroke.Name = "UIStroke"
	UIStroke.Color = Color3.new(0.11, 0.11, 0.11)
	UIStroke.Thickness = 1.8
	UIStroke.LineJoinMode = Enum.LineJoinMode.Miter
	UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke.Parent = Main

	local Tabs = Instance.new("Folder")
	Tabs.Name = "Tabs"
	Tabs.Parent = Main

	local MobileToggleButton = Instance.new("TextButton")
	MobileToggleButton.Name = "MobileToggleButton"
	MobileToggleButton.AnchorPoint = Vector2.new(1, 0)
	MobileToggleButton.Size = UDim2.new(0, 84, 0, 30)
	MobileToggleButton.Position = UDim2.new(1, -12, 0, 12)
	MobileToggleButton.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
	MobileToggleButton.BorderSizePixel = 0
	MobileToggleButton.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	MobileToggleButton.TextColor3 = Color3.new(0.92, 0.92, 0.92)
	MobileToggleButton.Text = "Hide UI"
	MobileToggleButton.TextSize = 14
	MobileToggleButton.Visible = UIS.TouchEnabled
	MobileToggleButton.ZIndex = 1000
	MobileToggleButton.Parent = P

	local MobileToggleStroke = Instance.new("UIStroke")
	MobileToggleStroke.Color = accent_color
	MobileToggleStroke.Thickness = 1
	MobileToggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	MobileToggleStroke.Parent = MobileToggleButton

	local function setMobileToggleText()
		MobileToggleButton.Text = Main.Visible and "Hide UI" or "Show UI"
	end

	local function toggleMainVisibility()
		local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		if Main.Visible then
			local objs = {Main}
			for _, obj in pairs(Main:GetDescendants()) do table.insert(objs, obj) end
			for _, obj in pairs(objs) do
				if obj:IsA("GuiObject") then
					if obj:GetAttribute("orig_bg") == nil then obj:SetAttribute("orig_bg", obj.BackgroundTransparency) end
					TweenService:Create(obj, tweenInfo, {BackgroundTransparency = 1}):Play()
					if obj:IsA("TextLabel") or obj:IsA("TextButton") then
						if obj:GetAttribute("orig_text") == nil then obj:SetAttribute("orig_text", obj.TextTransparency) end
						TweenService:Create(obj, tweenInfo, {TextTransparency = 1}):Play()
					end
					if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
						if obj:GetAttribute("orig_image") == nil then obj:SetAttribute("orig_image", obj.ImageTransparency) end
						TweenService:Create(obj, tweenInfo, {ImageTransparency = 1}):Play()
					end
				end
				if obj:IsA("UIStroke") then
					if obj:GetAttribute("orig_stroke") == nil then obj:SetAttribute("orig_stroke", obj.Transparency) end
					obj.Transparency = 1
				end
			end
			task.wait(0.1)
			Main.Visible = false
		else
			Main.Visible = true
			local objs = {Main}
			for _, obj in pairs(Main:GetDescendants()) do table.insert(objs, obj) end
			for _, obj in pairs(objs) do
				if obj:IsA("GuiObject") then
					if obj:GetAttribute("orig_bg") then obj.BackgroundTransparency = obj:GetAttribute("orig_bg") end
					if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj:GetAttribute("orig_text") then obj.TextTransparency = obj:GetAttribute("orig_text") end
					if (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and obj:GetAttribute("orig_image") then obj.ImageTransparency = obj:GetAttribute("orig_image") end
				end
				if obj:IsA("UIStroke") and obj:GetAttribute("orig_stroke") then
					obj.Transparency = obj:GetAttribute("orig_stroke")
				end
			end
		end
		setMobileToggleText()
	end

	MobileToggleButton.MouseButton1Click:Connect(toggleMainVisibility)

	UIS.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.Delete then
			toggleMainVisibility()
		end
	end)
	function dragify(frameToDrag, dragHandle)
		dragHandle = dragHandle or frameToDrag
		local dragToggle, dragInput, dragStart, startPos
		local function updateInput(input)
			local Delta = input.Position - dragStart
			local Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
			game:GetService("TweenService"):Create(frameToDrag, TweenInfo.new(0), {Position = Position}):Play()
		end

		local function shouldStartDrag(input)
			if UIS:GetFocusedTextBox() ~= nil then
				return false
			end

			-- On touch devices (mobile), only drag from top header bar so scrolling in sections works
			if input.UserInputType == Enum.UserInputType.Touch then
				local hPos = dragHandle.AbsolutePosition
				local hSize = dragHandle.AbsoluteSize
				local p = input.Position
				if p.X >= hPos.X and p.X <= hPos.X + hSize.X and p.Y >= hPos.Y and p.Y <= hPos.Y + hSize.Y then
					for _, child in pairs(dragHandle:GetDescendants()) do
						if child:IsA("TextButton") or child:IsA("ImageButton") then
							local bPos = child.AbsolutePosition
							local bSize = child.AbsoluteSize
							if p.X >= bPos.X and p.X <= bPos.X + bSize.X and p.Y >= bPos.Y and p.Y <= bPos.Y + bSize.Y then
								return false
							end
						end
					end
					return true
				end
				return false
			end

			-- On mouse (PC), allow dragging except when clicking controls
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				for _, child in pairs(frameToDrag:GetDescendants()) do
					if child:IsA("GuiObject") and (child:IsA("TextButton") or child:IsA("ImageButton") or child:IsA("TextBox") or child.Name:lower():find("slider")) then
						local absPos = child.AbsolutePosition
						local absSize = child.AbsoluteSize
						if input.Position.X >= absPos.X and input.Position.X <= absPos.X + absSize.X and
							input.Position.Y >= absPos.Y and input.Position.Y <= absPos.Y + absSize.Y then
							return false
						end
					end
				end
				return true
			end

			return false
		end

		frameToDrag.InputBegan:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and shouldStartDrag(input) then
				dragToggle = true
				dragStart = input.Position
				startPos = frameToDrag.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragToggle = false
					end
				end)
			end
		end)

		frameToDrag.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)

		UIS.InputChanged:Connect(function(input)
			if input == dragInput and dragToggle then
				updateInput(input)
			end
		end)
	end

	dragify(Main, Frame)

	function window:GetScale()
		return Ui_Scale.Scale
	end

	function window:SetScale(scale)
		Ui_Scale.Scale = scale
	end

	function window:CreateWatermark(watermarkTitle, watermarkTitleColor, watermarkTitleIcon)
		local mark = {}

		local watamark = Instance.new("Frame")
		watamark.Name = "Watermark"
		watamark.AnchorPoint = Vector2.new(1, 0)
		watamark.Size = UDim2.new(0, 0, 0, 0)
		watamark.AutomaticSize = Enum.AutomaticSize.XY
		watamark.BackgroundColor3 = Color3.new(0, 0, 0)
		watamark.BackgroundTransparency = 0
		watamark.BorderSizePixel = 0
		watamark.Parent = P

		local glassGradient = Instance.new("UIGradient")
		glassGradient.Name = "GlassGradient"
		glassGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7062499523162842), NumberSequenceKeypoint.new(0.10109288990497589, 0.668749988079071), NumberSequenceKeypoint.new(0.1912568211555481, 0.6124999523162842), NumberSequenceKeypoint.new(0.2704918086528778, 0.574999988079071), NumberSequenceKeypoint.new(0.4071038067340851, 0.42500001192092896), NumberSequenceKeypoint.new(0.5956283807754517, 0.3125), NumberSequenceKeypoint.new(0.6612021923065186, 0.34375), NumberSequenceKeypoint.new(0.737704873085022, 0.41874998807907104), NumberSequenceKeypoint.new(0.8265026807785034, 0.5249999761581421), NumberSequenceKeypoint.new(0.8866119980812073, 0.6437499523162842), NumberSequenceKeypoint.new(1, 0.8687499761581421)})
		glassGradient.Parent = watamark
		
   

		local function updatePosition()
			local topOffset = (MobileToggleButton and MobileToggleButton.Visible) and 48 or 12
			watamark.Position = UDim2.new(1, -12, 0, topOffset)
		end
		updatePosition()

		if MobileToggleButton then
			MobileToggleButton:GetPropertyChangedSignal("Visible"):Connect(updatePosition)
		end


		local watermarkPadding = Instance.new("UIPadding")
		watermarkPadding.Name = "UIPadding"
		watermarkPadding.PaddingLeft = UDim.new(0, 10)
		watermarkPadding.PaddingRight = UDim.new(0, 10)
		watermarkPadding.PaddingTop = UDim.new(0, 2)
		watermarkPadding.PaddingBottom = UDim.new(0, 2)
		watermarkPadding.Parent = watamark

		local watermarkScale = Instance.new("UIScale")
		watermarkScale.Name = "WatermarkScale"
		watermarkScale.Scale = (Ui_Scale and Ui_Scale.Scale) or 1
		watermarkScale.Parent = watamark

		if Ui_Scale then
			Ui_Scale:GetPropertyChangedSignal("Scale"):Connect(function()
				watermarkScale.Scale = Ui_Scale.Scale
			end)
		end

		local list = Instance.new("Frame")
		list.Name = "list"
		list.Parent = watamark
		list.BackgroundTransparency = 1
		list.BorderSizePixel = 0
		list.Size = UDim2.new(0, 0, 0, 18)
		list.AutomaticSize = Enum.AutomaticSize.X
		list.Position = UDim2.new(0, 0, 0, 0)

		local layout = Instance.new("UIListLayout")
		layout.Name = "UIListLayout"
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		layout.Padding = UDim.new(0, 12)
		layout.Parent = list

		local itemOrder = 10

		local titleItem = Instance.new("Frame")
		titleItem.Name = "TitleItem"
		titleItem.Size = UDim2.new(0, 0, 0, 18)
		titleItem.AutomaticSize = Enum.AutomaticSize.X
		titleItem.BackgroundTransparency = 1
		titleItem.BorderSizePixel = 0
		titleItem.LayoutOrder = 1
		titleItem.Visible = false
		titleItem.Parent = list

		local titleItemLayout = Instance.new("UIListLayout")
		titleItemLayout.Name = "UIListLayout"
		titleItemLayout.FillDirection = Enum.FillDirection.Horizontal
		titleItemLayout.SortOrder = Enum.SortOrder.LayoutOrder
		titleItemLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		titleItemLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		titleItemLayout.Padding = UDim.new(0, 4)
		titleItemLayout.Parent = titleItem

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.Size = UDim2.new(0, 0, 1, 0)
		titleLabel.AutomaticSize = Enum.AutomaticSize.X
		titleLabel.BackgroundTransparency = 1
		titleLabel.BorderSizePixel = 0
		titleLabel.TextColor3 = accent_color
		titleLabel.Text = ""
		titleLabel.TextSize = 14
		titleLabel.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextYAlignment = Enum.TextYAlignment.Center
		titleLabel.LayoutOrder = 1
		titleLabel.Visible = false
		titleLabel.Parent = titleItem

		local titleSecondLabel = Instance.new("TextLabel")
		titleSecondLabel.Name = "TitleSecondLabel"
		titleSecondLabel.Size = UDim2.new(0, 0, 1, 0)
		titleSecondLabel.AutomaticSize = Enum.AutomaticSize.X
		titleSecondLabel.BackgroundTransparency = 1
		titleSecondLabel.BorderSizePixel = 0
		titleSecondLabel.TextColor3 = Color3.fromRGB(240, 243, 248)
		titleSecondLabel.Text = ""
		titleSecondLabel.TextSize = 13
		titleSecondLabel.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
		titleSecondLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleSecondLabel.TextYAlignment = Enum.TextYAlignment.Center
		titleSecondLabel.LayoutOrder = 2
		titleSecondLabel.Visible = false
		titleSecondLabel.Parent = titleItem

		local function applyTitle(arg1, arg2, arg3)
			local firstText = ""
			local secondText = ""
			local titleColor = nil
			local secondColor = nil

			if type(arg1) == "table" then
				firstText = tostring(arg1.Text or arg1.Title or arg1.FirstText or "")
				secondText = tostring(arg1.SecondText or arg1.SubTitle or arg1.Suffix or "")
				titleColor = arg1.Color or arg1.TitleColor or arg1.FirstColor
				secondColor = arg1.SecondColor
			else
				firstText = arg1 ~= nil and tostring(arg1) or ""
				if typeof(arg2) == "Color3" then
					titleColor = arg2
					if typeof(arg3) == "Color3" then
						secondColor = arg3
					end
				elseif type(arg2) == "string" then
					secondText = arg2
					if typeof(arg3) == "Color3" then
						titleColor = arg3
					end
				elseif arg2 ~= nil then
					secondText = tostring(arg2)
				end
			end

			titleLabel.Text = firstText
			titleLabel.Visible = (firstText ~= "")
			if titleColor then
				titleLabel.TextColor3 = titleColor
			end

			titleSecondLabel.Text = secondText
			titleSecondLabel.Visible = (secondText ~= "")
			if secondColor then
				titleSecondLabel.TextColor3 = secondColor
			end

			titleItem.Visible = (titleLabel.Visible or titleSecondLabel.Visible)
		end

		if watermarkTitle ~= nil then
			applyTitle(watermarkTitle, watermarkTitleColor)
		end

		function mark.SetTitle(selfOrText, ...)
			if type(selfOrText) == "table" and selfOrText.SetTitle == mark.SetTitle then
				applyTitle(...)
			else
				applyTitle(selfOrText, ...)
			end
		end

		function mark.GetTitle()
			return titleLabel.Text
		end

		function mark.SetTitleColor(selfOrCol, col)
			local color = typeof(selfOrCol) == "Color3" and selfOrCol or col
			if color then
				titleLabel.TextColor3 = color
			end
		end

		function mark.CreateDivider(color, transparency)
			local div = Instance.new("Frame")
			div.Name = "divider"
			div.Size = UDim2.new(0, 1, 0, 13)
			div.BackgroundColor3 = color or Color3.fromRGB(255, 255, 255)
			div.BackgroundTransparency = transparency or 0.85
			div.BorderSizePixel = 0
			div.LayoutOrder = itemOrder
			itemOrder = itemOrder + 1
			div.Parent = list
			return div
		end

		function mark.CreateItem(iconVal, firstVal, secondVal, firstCol, secondCol)
			local Item = {}
			local item = Instance.new("Frame")
			item.Name = "item"
			item.Size = UDim2.new(0, 0, 0, 18)
			item.AutomaticSize = Enum.AutomaticSize.X
			item.BackgroundTransparency = 1
			item.BorderSizePixel = 0
			item.LayoutOrder = itemOrder
			itemOrder = itemOrder + 1
			item.Parent = list

			local itemLayout = Instance.new("UIListLayout")
			itemLayout.Name = "UIListLayout"
			itemLayout.FillDirection = Enum.FillDirection.Horizontal
			itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
			itemLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			itemLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			itemLayout.Padding = UDim.new(0, 4)
			itemLayout.Parent = item

			local hasIcon = (iconVal ~= "" and iconVal ~= nil)

			local iconContainer = Instance.new("Frame")
			iconContainer.Name = "iconContainer"
			iconContainer.Size = UDim2.new(0, 15, 1, 0)
			iconContainer.BackgroundTransparency = 1
			iconContainer.BorderSizePixel = 0
			iconContainer.LayoutOrder = 1
			iconContainer.Visible = hasIcon
			iconContainer.Parent = item

			local icon = Instance.new("ImageLabel")
			icon.Name = "icon"
			icon.Size = UDim2.new(0, 15, 0, 15)
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Position = UDim2.new(0.5, 0, 0.5, 0)
			icon.BackgroundTransparency = 1
			icon.BorderSizePixel = 0
			icon.ScaleType = Enum.ScaleType.Fit
			icon.Image = iconVal or ""
			icon.ImageColor3 = accent_color
			icon.Visible = hasIcon
			icon.Parent = iconContainer

			local FirstLabel = Instance.new("TextLabel")
			FirstLabel.Name = "FirstLabel"
			FirstLabel.Size = UDim2.new(0, 0, 1, 0)
			FirstLabel.AutomaticSize = Enum.AutomaticSize.X
			FirstLabel.BackgroundTransparency = 1
			FirstLabel.BorderSizePixel = 0
			FirstLabel.TextColor3 = accent_color
			FirstLabel.Text = firstVal ~= nil and tostring(firstVal) or ""
			FirstLabel.TextSize = 13
			FirstLabel.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
			FirstLabel.TextXAlignment = Enum.TextXAlignment.Left
			FirstLabel.TextYAlignment = Enum.TextYAlignment.Center
			FirstLabel.LayoutOrder = 2
			FirstLabel.Visible = (FirstLabel.Text ~= "")
			FirstLabel.Parent = item

			local SecondLabel = Instance.new("TextLabel")
			SecondLabel.Name = "SecondLabel"
			SecondLabel.Size = UDim2.new(0, 0, 1, 0)
			SecondLabel.AutomaticSize = Enum.AutomaticSize.X
			SecondLabel.BackgroundTransparency = 1
			SecondLabel.BorderSizePixel = 0
			SecondLabel.TextColor3 = secondCol or Color3.fromRGB(240, 243, 248)
			SecondLabel.Text = secondVal ~= nil and tostring(secondVal) or ""
			SecondLabel.TextSize = 13
			SecondLabel.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
			SecondLabel.TextXAlignment = Enum.TextXAlignment.Left
			SecondLabel.TextYAlignment = Enum.TextYAlignment.Center
			SecondLabel.LayoutOrder = 3
			SecondLabel.Visible = (SecondLabel.Text ~= "")
			SecondLabel.Parent = item

			local itemMethods = {
				SetIcon = function(self, image, color)
					if image ~= nil then
						icon.Image = tostring(image)
						local has = (icon.Image ~= "")
						icon.Visible = has
						iconContainer.Visible = has
					end
					if color then
						icon.ImageColor3 = color
					end
				end,
				SetFirstText = function(self, text, color)
					if text ~= nil then
						FirstLabel.Text = tostring(text)
						FirstLabel.Visible = (FirstLabel.Text ~= "")
					end
					if color then
						FirstLabel.TextColor3 = color
					end
				end,
				SetSecondText = function(self, text, color)
					if text ~= nil then
						SecondLabel.Text = tostring(text)
						SecondLabel.Visible = (SecondLabel.Text ~= "")
					end
					if color then
						SecondLabel.TextColor3 = color
					end
				end,
				SetTextSize = function(self, size)
					if size then
						FirstLabel.TextSize = size
						SecondLabel.TextSize = size
					end
				end,
				SetFontFace = function(self, fontFace)
					if fontFace then
						FirstLabel.FontFace = fontFace
						SecondLabel.FontFace = fontFace
					end
				end,
				SetFontWeight = function(self, firstWeight, secondWeight)
					if firstWeight then
						FirstLabel.FontFace = Font.new("rbxassetid://16658221428", firstWeight, Enum.FontStyle.Normal)
					end
					if secondWeight then
						SecondLabel.FontFace = Font.new("rbxassetid://16658221428", secondWeight, Enum.FontStyle.Normal)
					end
				end,
				SetVisible = function(self, visible)
					item.Visible = visible
				end,
				Destroy = function(self)
					item:Destroy()
				end,
			}

			local itemInstances = {
				Frame = item,
				item = item,
				Icon = icon,
				icon = icon,
				IconContainer = iconContainer,
				iconContainer = iconContainer,
				ImageLabel = icon,
				FirstLabel = FirstLabel,
				SecondLabel = SecondLabel,
				Layout = itemLayout,
			}

			setmetatable(Item, {
				__index = function(self, key)
					if itemMethods[key] then
						return itemMethods[key]
					end
					if itemInstances[key] then
						return itemInstances[key]
					end
					if key == "IconId" or key == "iconId" or key == "Icon" or key == "icon" then
						return icon.Image
					elseif key == "IconColor" or key == "iconColor" then
						return icon.ImageColor3
					elseif key == "FirstText" or key == "firstText" then
						return FirstLabel.Text
					elseif key == "SecondText" or key == "secondText" then
						return SecondLabel.Text
					elseif key == "FirstColor" or key == "firstColor" then
						return FirstLabel.TextColor3
					elseif key == "SecondColor" or key == "secondColor" then
						return SecondLabel.TextColor3
					elseif key == "TextSize" or key == "textSize" then
						return FirstLabel.TextSize
					elseif key == "FontFace" or key == "fontFace" then
						return FirstLabel.FontFace
					elseif key == "FirstFontFace" or key == "firstFontFace" then
						return FirstLabel.FontFace
					elseif key == "SecondFontFace" or key == "secondFontFace" then
						return SecondLabel.FontFace
					elseif key == "Visible" or key == "visible" then
						return item.Visible
					end
					return rawget(self, key)
				end,
				__newindex = function(self, key, value)
					if key == "IconId" or key == "iconId" or key == "Icon" or key == "icon" then
						icon.Image = tostring(value or "")
						local has = (icon.Image ~= "")
						icon.Visible = has
						iconContainer.Visible = has
					elseif key == "IconColor" or key == "iconColor" then
						icon.ImageColor3 = value
					elseif key == "FirstText" or key == "firstText" then
						FirstLabel.Text = tostring(value or "")
						FirstLabel.Visible = (FirstLabel.Text ~= "")
					elseif key == "SecondText" or key == "secondText" then
						SecondLabel.Text = tostring(value or "")
						SecondLabel.Visible = (SecondLabel.Text ~= "")
					elseif key == "FirstColor" or key == "firstColor" then
						FirstLabel.TextColor3 = value
					elseif key == "SecondColor" or key == "secondColor" then
						SecondLabel.TextColor3 = value
					elseif key == "TextSize" or key == "textSize" then
						FirstLabel.TextSize = value
						SecondLabel.TextSize = value
					elseif key == "FontFace" or key == "fontFace" then
						FirstLabel.FontFace = value
						SecondLabel.FontFace = value
					elseif key == "FirstFontFace" or key == "firstFontFace" then
						FirstLabel.FontFace = value
					elseif key == "SecondFontFace" or key == "secondFontFace" then
						SecondLabel.FontFace = value
					elseif key == "FontWeight" or key == "fontWeight" then
						FirstLabel.FontFace = Font.new("rbxassetid://16658221428", value, Enum.FontStyle.Normal)
						SecondLabel.FontFace = Font.new("rbxassetid://16658221428", value, Enum.FontStyle.Normal)
					elseif key == "Visible" or key == "visible" then
						item.Visible = value
					else
						rawset(self, key, value)
					end
				end,
			})

			return Item
		end

		local markMethods = {
			SetVisible = function(self, visible)
				watamark.Visible = visible
			end,
			SetScale = function(self, scale)
				watermarkScale.Scale = scale
			end,
			SetPosition = function(self, position)
				watamark.Position = position
			end,
			SetTitle = function(self, ...)
				applyTitle(...)
			end,
			GetTitle = function(self)
				return titleLabel.Text
			end,
			SetTitleColor = function(self, col)
				local color = typeof(self) == "Color3" and self or col
				if color then titleLabel.TextColor3 = color end
			end,
			SetTitleIcon = function(self, icon)
				local image = (type(self) == "string" or typeof(self) == "Content") and self or icon
				if image ~= nil then
					titleIcon.Image = tostring(image)
					local has = (titleIcon.Image ~= "")
					titleIcon.Visible = has
					titleIconContainer.Visible = has
					titleItem.Visible = (titleLabel.Visible or titleSecondLabel.Visible or titleIconContainer.Visible)
				end
			end,
			Destroy = function(self)
				watamark:Destroy()
			end,
		}

		local markInstances = {
			Frame = watamark,
			Watermark = watamark,
			List = list,
			list = list,
			Scale = watermarkScale,
			Layout = layout,
			Padding = watermarkPadding,
			GlassGradient = glassGradient,
			TitleItem = titleItem,
			titleItem = titleItem,
			TitleFrame = titleItem,
			titleFrame = titleItem,
			Title = titleItem,
			title = titleItem,
			TitleLabel = titleLabel,
			titleLabel = titleLabel,
			TitleSecondLabel = titleSecondLabel,
			titleSecondLabel = titleSecondLabel,
		}

		setmetatable(mark, {
			__index = function(self, key)
				if markMethods[key] then
					return markMethods[key]
				end
				if markInstances[key] then
					return markInstances[key]
				end
				if key == "Visible" or key == "visible" then
					return watamark.Visible
				elseif key == "Title" or key == "title" then
					return titleLabel.Text
				elseif key == "TitleColor" or key == "titleColor" then
					return titleLabel.TextColor3
				end
				return rawget(self, key)
			end,
			__newindex = function(self, key, value)
				if key == "Visible" or key == "visible" then
					watamark.Visible = value
				elseif key == "Title" or key == "title" then
					applyTitle(value)
				elseif key == "TitleColor" or key == "titleColor" then
					if typeof(value) == "Color3" then
						titleLabel.TextColor3 = value
					end
				else
					rawset(self, key, value)
				end
			end,
		})

		return mark
	end

	function window:CreateIndicator(iconid, label)
		    local indicatorTemplate = Instance.new("Frame")
    indicatorTemplate.Size = UDim2.new(0, 0, 0, 36)
    indicatorTemplate.AutomaticSize = Enum.AutomaticSize.X
    indicatorTemplate.BorderColor3 = Color3.new(0, 0, 0)
    indicatorTemplate.Position = UDim2.new(0, 0, 0.47077921, 0)
    indicatorTemplate.BorderSizePixel = 0
    indicatorTemplate.BackgroundColor3 = Color3.new(0, 0, 0)
    indicatorTemplate.Parent = IndicatorContainer

    local UIGradient = Instance.new("UIGradient")
    UIGradient.Name = "UIGradient"
    UIGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.7062499523162842),
        NumberSequenceKeypoint.new(0.10109288990497589, 0.668749988079071),
        NumberSequenceKeypoint.new(0.18852458894252777, 0.59375),
        NumberSequenceKeypoint.new(0.26639342308044434, 0.4624999761581421),
        NumberSequenceKeypoint.new(0.39754098653793335, 0.36250001192092896),
        NumberSequenceKeypoint.new(0.5956283807754517, 0.3125),
        NumberSequenceKeypoint.new(0.7581967115402222, 0.32499998807907104),
        NumberSequenceKeypoint.new(0.800546407699585, 0.375),
        NumberSequenceKeypoint.new(0.8852458596229553, 0.4937499761581421),
        NumberSequenceKeypoint.new(1, 0.7374999523162842)
    })
    UIGradient.Parent = indicatorTemplate

    local ImageLabel = Instance.new("ImageLabel")
    ImageLabel.Size = UDim2.new(0, 30, 0, 30)
    ImageLabel.BorderColor3 = Color3.new(0, 0, 0)
    ImageLabel.BackgroundTransparency = 1
    ImageLabel.Position = UDim2.new(0, 7, 0.5, 0)
    ImageLabel.BorderSizePixel = 0
    ImageLabel.BackgroundColor3 = Color3.new(1, 1, 1)
    ImageLabel.Image = iconid
    ImageLabel.Parent = indicatorTemplate
	ImageLabel.AnchorPoint = Vector2.new(0,0.5)

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(0, 0, 0, 30)
    TextLabel.AutomaticSize = Enum.AutomaticSize.X
    TextLabel.BorderColor3 = Color3.new(0, 0, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Position = UDim2.new(0, 39, 0.5, 0)
    TextLabel.BorderSizePixel = 0
    TextLabel.BackgroundColor3 = Color3.new(1, 1, 1)
    TextLabel.TextColor3 = Color3.new(1, 1, 1)
    TextLabel.Text = tostring(label)
    TextLabel.TextSize = 29
    TextLabel.FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    TextLabel.Parent = indicatorTemplate
	TextLabel.AnchorPoint = Vector2.new(0,0.5)

	local tUIStroke = Instance.new("UIStroke")
    tUIStroke.Name = "UIStroke"
    tUIStroke.Thickness = 1
    tUIStroke.Parent = TextLabel

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Name = "UIStroke"
    UIStroke.Thickness = 0.5
    UIStroke.Parent = indicatorTemplate

    local UIPadding = Instance.new("UIPadding")
    UIPadding.PaddingRight = UDim.new(0, 8)
    UIPadding.Parent = indicatorTemplate

    local currentColor = Color3.new(1, 1, 1)
    ImageLabel.ImageColor3 = currentColor
    TextLabel.TextColor3 = currentColor

    local Indicator = {}

    local methods = {
        SetColor = function(self, color)
            currentColor = color
            ImageLabel.ImageColor3 = color
            TextLabel.TextColor3 = color
        end,
        SetVisible = function(self, visible)
            indicatorTemplate.Visible = visible
        end,
        SetText = function(self, text)
            TextLabel.Text = tostring(text)
        end,
        Destroy = function(self)
            indicatorTemplate:Destroy()
        end,
    }

    local instances = {
        Frame = indicatorTemplate,
        Icon = ImageLabel,
        ImageLabel = ImageLabel,
        Text = TextLabel,
        TextLabel = TextLabel,
        Stroke = UIStroke,
        UIStroke = UIStroke,
    }

    setmetatable(Indicator, {
        __index = function(self, key)
            if methods[key] then
                return methods[key]
            end
            if key == "Color" or key == "color" then
                return currentColor
            elseif key == "Visible" or key == "visible" then
                return indicatorTemplate.Visible
            elseif instances[key] then
                return instances[key]
            end
            return rawget(self, key)
        end,
        __newindex = function(self, key, value)
            if key == "Color" or key == "color" then
                currentColor = value
                ImageLabel.ImageColor3 = value
                TextLabel.TextColor3 = value
            elseif key == "Visible" or key == "visible" then
                indicatorTemplate.Visible = value
            elseif key == "Text" and type(value) == "string" then
                TextLabel.Text = value
            else
                rawset(self, key, value)
            end
        end
    })

    return Indicator
	end

	function window:CreateTab(tabname)
		local tab = {}

		local TabButton = Instance.new("TextButton")
		TabButton.Name = tabname .. "_Button"
		TabButton.AutomaticSize = Enum.AutomaticSize.X
		TabButton.Size = UDim2.new(0, 0, 0, 26)
		TabButton.BackgroundTransparency = 1
		TabButton.BorderSizePixel = 0
		TabButton.Text = tabname
		TabButton.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium)
		TabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
		TabButton.Parent = Frame_3
		if tabname == "Misc" then
			TabButton.LayoutOrder = 9999
		else
			TabButton.LayoutOrder = #window.Tabs + 1
		end

		local UIPadding = Instance.new("UIPadding")
		UIPadding.PaddingLeft = UDim.new(0, 4)
		UIPadding.PaddingRight = UDim.new(0, 4)
		UIPadding.Parent = TabButton

		local UITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
		UITextSizeConstraint_2.MinTextSize = 14
		UITextSizeConstraint_2.Parent = TabButton

		local TabFrame = Instance.new("Frame")
		TabFrame.Name = tabname
		TabFrame.Size = UDim2.new(1, 0, 1, -28)
		TabFrame.Position = UDim2.new(0, 0, 0, 28)
		TabFrame.BackgroundTransparency = 1
		TabFrame.Visible = false
		TabFrame.Parent = Tabs

		local function createColumns(parentFrame)
			local colLeft = Instance.new("ScrollingFrame")
			colLeft.Size = UDim2.new(0.5, 0, 1, 0)
			colLeft.BackgroundTransparency = 1
			colLeft.BorderSizePixel = 0
			colLeft.CanvasSize = UDim2.new(0, 0, 0, 0)
			colLeft.AutomaticCanvasSize = Enum.AutomaticSize.None
			colLeft.ScrollBarImageColor3 = accent_color
			colLeft.ScrollBarImageTransparency = 0
			colLeft.ScrollBarThickness = 0
			colLeft.ScrollingDirection = Enum.ScrollingDirection.Y
			colLeft.ScrollingEnabled = false
			colLeft.Parent = parentFrame

			local colRight = Instance.new("ScrollingFrame")
			colRight.Size = UDim2.new(0.5, 0, 1, 0)
			colRight.Position = UDim2.new(0.5, 0, 0, 0)
			colRight.BackgroundTransparency = 1
			colRight.BorderSizePixel = 0
			colRight.CanvasSize = UDim2.new(0, 0, 0, 0)
			colRight.AutomaticCanvasSize = Enum.AutomaticSize.None
			colRight.ScrollBarImageColor3 = accent_color
			colRight.ScrollBarImageTransparency = 0
			colRight.ScrollBarThickness = 0
			colRight.ScrollingDirection = Enum.ScrollingDirection.Y
			colRight.ScrollingEnabled = false
			colRight.Parent = parentFrame

			local LeftLayout = Instance.new("UIListLayout")
			LeftLayout.Padding = UDim.new(0, 8)
			LeftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			LeftLayout.Parent = colLeft

			local RightLayout = Instance.new("UIListLayout")
			RightLayout.Padding = UDim.new(0, 8)
			RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			RightLayout.Parent = colRight

			local LeftPadding = Instance.new("UIPadding")
			LeftPadding.PaddingTop = UDim.new(0, 10)
			LeftPadding.PaddingBottom = UDim.new(0, 10)
			LeftPadding.Parent = colLeft

			local RightPadding = Instance.new("UIPadding")
			RightPadding.PaddingTop = UDim.new(0, 10)
			RightPadding.PaddingBottom = UDim.new(0, 10)
			RightPadding.Parent = colRight

			return colLeft, colRight
		end

		local Left, Right = createColumns(TabFrame)
		tab.Subtabs = {}
		tab.ActiveSubtab = nil
		tab.SubtabBar = nil

		local function activateSubtab(targetSubtab)
			for _, st in ipairs(tab.Subtabs) do
				if st == targetSubtab then
					st.Content.Visible = true
					st.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					st.Content.Visible = false
					st.Button.TextColor3 = Color3.fromRGB(150, 150, 150)
				end
			end
			tab.ActiveSubtab = targetSubtab
		end

		TabButton.MouseButton1Click:Connect(function()
			if window.ActiveTab == TabFrame then return end

			for _, t in pairs(window.Tabs) do
				t.Frame.Visible = false
				t.Button.TextColor3 = Color3.fromRGB(150, 150, 150)
			end

			TabFrame.Visible = true
			TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)

			window.ActiveTab = TabFrame

			if #tab.Subtabs > 0 and tab.ActiveSubtab then
				activateSubtab(tab.ActiveSubtab)
			end
		end)

		tab.Frame = TabFrame
		tab.Button = TabButton

		table.insert(window.Tabs, tab)

		for i, t in ipairs(window.Tabs) do
			if t.Button.Text ~= "Misc" then
				t.Button.LayoutOrder = i
			end
		end

		if #window.Tabs == 1 then
			TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			TabFrame.Visible = true
			window.ActiveTab = TabFrame
		end

		local function createSectionInternal(targetLeft, targetRight, targetOwner, sectionName, Parent)
			local sect = {}

			local section = Instance.new("Frame")
			section.Name = "Section"
			section.Size = UDim2.new(1, -16, 0, 0)
			section.AutomaticSize = Enum.AutomaticSize.None
			section.ClipsDescendants = true
			section.BorderColor3 = Color3.new(0, 0, 0)
			section.BorderSizePixel = 0
			section.Position = UDim2.new(0, 0, 0, 0)
			section.BackgroundColor3 = Color3.fromRGB(21,21,21)
			if Parent == "Left" then
				section.Parent = targetLeft
			elseif Parent == "Right" then
				section.Parent = targetRight
			end
			local UIStroke = Instance.new("UIStroke")
			UIStroke.Name = "UIStroke"
			UIStroke.Color = Color3.new(0.16, 0.16, 0.16)
			UIStroke.Thickness = 0.7
			UIStroke.LineJoinMode = Enum.LineJoinMode.Miter
			UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			UIStroke.Parent = section

			local NameHolder = Instance.new("Frame")
			NameHolder.Name = "Frame"
			NameHolder.ZIndex = 14
			NameHolder.Size = UDim2.new(1, 0, 0, 11)
			NameHolder.BorderColor3 = Color3.new(0, 0, 0)
			NameHolder.BorderSizePixel = 0
			NameHolder.BackgroundTransparency = 1
			NameHolder.BackgroundColor3 = Color3.new(1, 1, 1)
			NameHolder.Parent = section

			local SectionName = Instance.new("TextLabel")
			SectionName.Name = "SectionName"
			SectionName.ZIndex = 13
			SectionName.Size = UDim2.new(1, 0, 1.55, 0)
			SectionName.BorderColor3 = Color3.new(0, 0, 0)
			SectionName.BorderSizePixel = 0
			SectionName.BackgroundTransparency = 1
			SectionName.BackgroundColor3 = Color3.new(1, 1, 1)
			SectionName.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
			SectionName.TextColor3 = Color3.new(0.65, 0.65, 0.65)
			SectionName.Text = "  " .. sectionName
			SectionName.TextXAlignment = Enum.TextXAlignment.Left
			SectionName.Parent = NameHolder

			local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
			UITextSizeConstraint.Name = "UITextSizeConstraint"
			UITextSizeConstraint.MinTextSize = 14
			UITextSizeConstraint.Parent = SectionName

			local ScrollingFrame = Instance.new("ScrollingFrame")
			ScrollingFrame.Name = "ScrollingFrame"
			ScrollingFrame.Active = true
			ScrollingFrame.Size = UDim2.new(1, 0, 0, 0)
			ScrollingFrame.AutomaticSize = Enum.AutomaticSize.None
			ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
			ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
			ScrollingFrame.ScrollingEnabled = false
			ScrollingFrame.BorderColor3 = Color3.new(0, 0, 0)
			ScrollingFrame.BorderSizePixel = 0
			ScrollingFrame.BackgroundTransparency = 1
			ScrollingFrame.BackgroundColor3 = Color3.new(1, 1, 1)
			ScrollingFrame.ScrollBarImageColor3 = accent_color
			ScrollingFrame.ScrollBarImageTransparency = 0
			ScrollingFrame.ScrollBarThickness = 6
			ScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
			ScrollingFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
			ScrollingFrame.Parent = section

			local UIListLayout = Instance.new("UIListLayout")
			UIListLayout.Name = "UIListLayout"
			UIListLayout.Padding = UDim.new(0, 2)
			UIListLayout.Parent = ScrollingFrame
			UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
			UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

			local UIPadding = Instance.new("UIPadding")
			UIPadding.Name = "UIPadding"
			UIPadding.PaddingTop = UDim.new(0, 25)
			UIPadding.PaddingBottom = UDim.new(0, 6)
			UIPadding.Parent = ScrollingFrame

			local function getScale()
				local s = (Ui_Scale and Ui_Scale.Scale) or 1
				if type(s) ~= "number" or s <= 0 then
					return 1
				end
				return s
			end

			local function getPaddingOffset(paddingValue, unscaledSize)
				return paddingValue.Offset + (paddingValue.Scale * (unscaledSize or 0))
			end

			local function getObjectHeight(object)
				if not object then
					return 0
				end

				local scale = getScale()
				local unscaledAbsY = (object.AbsoluteSize.Y > 0) and (object.AbsoluteSize.Y / scale) or 0
				return math.max(unscaledAbsY, object.Size.Y.Offset)
			end

			local function getColumnPaddingHeight(column)
				local paddingHeight = 0
				local padding = column and column:FindFirstChildOfClass("UIPadding")

				if padding then
					local scale = getScale()
					local unscaledY = (column.AbsoluteSize.Y > 0) and (column.AbsoluteSize.Y / scale) or (Main.AbsoluteSize.Y > 28 and ((Main.AbsoluteSize.Y - 28) / scale) or 544)
					paddingHeight = paddingHeight
						+ getPaddingOffset(padding.PaddingTop, unscaledY)
						+ getPaddingOffset(padding.PaddingBottom, unscaledY)
				end

				return paddingHeight
			end

			local function getScrollContentHeight(scrollFrame)
				local contentHeight = 0
				local visibleChildren = 0
				local listLayout = scrollFrame and scrollFrame:FindFirstChildOfClass("UIListLayout")
				local scale = getScale()
				local unscaledScrollY = (scrollFrame and scrollFrame.AbsoluteSize.Y > 0)
					and (scrollFrame.AbsoluteSize.Y / scale)
					or (scrollFrame and scrollFrame.Size.Y.Offset or 0)
				local layoutPadding = listLayout and getPaddingOffset(listLayout.Padding, unscaledScrollY) or 0

				if not scrollFrame then
					return 0
				end

				for _, child in ipairs(scrollFrame:GetChildren()) do
					if child:IsA("GuiObject") and child.Visible then
						contentHeight = contentHeight + getObjectHeight(child)
						visibleChildren = visibleChildren + 1
					end
				end

				if visibleChildren > 1 then
					contentHeight = contentHeight + ((visibleChildren - 1) * layoutPadding)
				end

				local listLayoutContentHeight = (listLayout and listLayout.AbsoluteContentSize.Y > 0)
					and (listLayout.AbsoluteContentSize.Y / scale)
					or 0

				return math.max(math.floor(contentHeight + 0.5), math.floor(listLayoutContentHeight + 0.5))
			end

			local function getSectionContentHeight(targetSection)
				local scrollFrame = targetSection and targetSection:FindFirstChild("ScrollingFrame")
				local padding = scrollFrame and scrollFrame:FindFirstChildOfClass("UIPadding")
				local contentHeight = getScrollContentHeight(scrollFrame)

				if padding then
					local scale = getScale()
					local unscaledY = (scrollFrame and scrollFrame.AbsoluteSize.Y > 0)
						and (scrollFrame.AbsoluteSize.Y / scale)
						or (scrollFrame and scrollFrame.Size.Y.Offset or 0)
					contentHeight = contentHeight
						+ getPaddingOffset(padding.PaddingTop, unscaledY)
						+ getPaddingOffset(padding.PaddingBottom, unscaledY)
				end

				return math.max(contentHeight, 40)
			end

			local function applySectionHeight(targetSection, contentHeight, visibleHeight)
				local scrollFrame = targetSection and targetSection:FindFirstChild("ScrollingFrame")
				local roundedVisible = math.floor(visibleHeight + 0.5)
				local roundedContent = math.floor(contentHeight + 0.5)
				local canScroll = roundedContent > roundedVisible + 1

				if not scrollFrame then
					return
				end

				targetSection.Size = UDim2.new(1, -16, 0, roundedVisible)
				scrollFrame.Size = UDim2.new(1, 0, 1, 0)
				scrollFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(roundedContent, roundedVisible))
				scrollFrame.ScrollingEnabled = canScroll
				scrollFrame.ScrollBarThickness = canScroll and 6 or 0
				scrollFrame.VerticalScrollBarInset = canScroll and Enum.ScrollBarInset.ScrollBar or Enum.ScrollBarInset.None

				if not canScroll then
					scrollFrame.CanvasPosition = Vector2.new(0, 0)
				end
			end

			local function updateSectionScroll()
				local column = section.Parent

				if column and column:IsA("ScrollingFrame") then
					local scale = getScale()
					local columnLayout = column:FindFirstChildOfClass("UIListLayout")
					local columnHeight = (column.AbsoluteSize.Y > 0)
						and (column.AbsoluteSize.Y / scale)
						or (column.Parent and column.Parent.AbsoluteSize.Y > 0 and (column.Parent.AbsoluteSize.Y / scale) or (Main.AbsoluteSize.Y > 28 and ((Main.AbsoluteSize.Y - 28) / scale) or 544))
					local layoutPadding = columnLayout and getPaddingOffset(columnLayout.Padding, columnHeight) or 0
					local sections = {}
					local totalContentHeight = 0

					for _, child in ipairs(column:GetChildren()) do
						if child:IsA("Frame") and child.Name == "Section" and child.Visible then
							local contentHeight = getSectionContentHeight(child)

							table.insert(sections, {
								Frame = child,
								ContentHeight = contentHeight,
								VisibleHeight = contentHeight
							})

							totalContentHeight = totalContentHeight + contentHeight
						end
					end

					local gapHeight = math.max(#sections - 1, 0) * layoutPadding
					local colPaddingHeight = getColumnPaddingHeight(column)
					local availableHeight = columnHeight - colPaddingHeight - gapHeight
					availableHeight = math.max(availableHeight, #sections * 40)

					local overflow = totalContentHeight - availableHeight

					while overflow > 1 do
						local shrinkable = {}
						local shrinkCapacity = 0

						for _, sectionInfo in ipairs(sections) do
							local capacity = sectionInfo.VisibleHeight - 40

							if capacity > 0 then
								table.insert(shrinkable, sectionInfo)
								shrinkCapacity = shrinkCapacity + capacity
							end
						end

						if #shrinkable == 0 then
							break
						end

						local shrinkAmount = overflow / #shrinkable
						local usedShrink = 0

						for _, sectionInfo in ipairs(shrinkable) do
							local newHeight = math.max(sectionInfo.VisibleHeight - shrinkAmount, 40)

							usedShrink = usedShrink + (sectionInfo.VisibleHeight - newHeight)
							sectionInfo.VisibleHeight = newHeight
						end

						if usedShrink <= 0 then
							break
						end

						overflow = overflow - usedShrink
					end

					for _, sectionInfo in ipairs(sections) do
						applySectionHeight(sectionInfo.Frame, sectionInfo.ContentHeight, sectionInfo.VisibleHeight)
					end

					column.CanvasSize = UDim2.new(0, 0, 0, 0)
					column.ScrollingEnabled = false
					column.ScrollBarThickness = 0
					column.CanvasPosition = Vector2.new(0, 0)
				else
					local contentHeight = getSectionContentHeight(section)
					applySectionHeight(section, contentHeight, contentHeight)
				end
			end

			local function queueSectionScrollUpdate()
				task.defer(updateSectionScroll)
				task.delay(0.05, updateSectionScroll)
				task.delay(0.15, updateSectionScroll)
			end

			UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSectionScroll)
			UIPadding:GetPropertyChangedSignal("PaddingTop"):Connect(updateSectionScroll)
			UIPadding:GetPropertyChangedSignal("PaddingBottom"):Connect(updateSectionScroll)
			section:GetPropertyChangedSignal("Parent"):Connect(updateSectionScroll)
			section:GetPropertyChangedSignal("Visible"):Connect(updateSectionScroll)
			TabFrame:GetPropertyChangedSignal("Visible"):Connect(updateSectionScroll)
			TabFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSectionScroll)

			if targetOwner and targetOwner ~= TabFrame then
				targetOwner:GetPropertyChangedSignal("Visible"):Connect(updateSectionScroll)
				targetOwner:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSectionScroll)
			end

			if section.Parent then
				section.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSectionScroll)
			end

			if Ui_Scale then
				Ui_Scale:GetPropertyChangedSignal("Scale"):Connect(queueSectionScrollUpdate)
			end

			task.defer(updateSectionScroll)

			function sect:Resolve()
				return ScrollingFrame
			end

			local sectItems = {}
			local sectItemCount = 0

			local function extractOrderFromOptions(opt)
				if type(opt) == "table" then
					return opt.DisplayOrder or opt.displayOrder or opt.LayoutOrder or opt.layoutOrder or opt.Order or opt.order
				elseif type(opt) == "number" or (type(opt) == "string" and tonumber(opt)) then
					return tonumber(opt)
				end
				return nil
			end

			local function registerSectItem(name, obj, frame, initialOrder)
				sectItemCount = sectItemCount + 1
				local order = initialOrder
				if order == nil then
					order = sectItemCount
				else
					order = math.floor(tonumber(order) or sectItemCount)
				end
				frame.LayoutOrder = order

				local entry = {
					Name = name,
					Object = obj,
					Frame = frame,
				}
				table.insert(sectItems, entry)
				if name and name ~= "" then
					sectItems[name] = entry
				end
				sectItems[frame] = entry
				if obj then
					sectItems[obj] = entry
				end
				if globalLibraryItems then
					if name and name ~= "" then
						globalLibraryItems[name] = entry
					end
					globalLibraryItems[frame] = entry
					if obj then
						globalLibraryItems[obj] = entry
					end
				end
				return order
			end

			local function attachOrderMetatable(itemObj, frame)
				setmetatable(itemObj, {
					__index = function(self, key)
						if key == "LayoutOrder" or key == "DisplayOrder" or key == "Order" then
							return frame.LayoutOrder
						end
						return nil
					end,
					__newindex = function(self, key, value)
						if key == "LayoutOrder" or key == "DisplayOrder" or key == "Order" then
							local num = tonumber(value)
							if num then
								frame.LayoutOrder = math.floor(num)
								queueSectionScrollUpdate()
							end
							return
						end
						rawset(self, key, value)
					end
				})
			end

			local function applyOrderMethods(itemObj, frame)
				itemObj.Frame = frame
				itemObj.Instance = frame
				itemObj.GetDisplayOrder = function(self)
					return frame.LayoutOrder
				end
				itemObj.GetLayoutOrder = function(self)
					return frame.LayoutOrder
				end
				itemObj.GetOrder = function(self)
					return frame.LayoutOrder
				end
				itemObj.SetDisplayOrder = function(selfOrVal, val)
					local order = extractArg(selfOrVal, val, itemObj)
					local num = tonumber(order)
					if num then
						frame.LayoutOrder = math.floor(num)
						queueSectionScrollUpdate()
					end
				end
				itemObj.SetLayoutOrder = itemObj.SetDisplayOrder
				itemObj.SetOrder = itemObj.SetDisplayOrder
				attachOrderMetatable(itemObj, frame)
			end

			local function resolveSectItem(itemOrName)
				if itemOrName == nil then return nil end
				if sectItems[itemOrName] then
					return sectItems[itemOrName]
				end
				if type(itemOrName) == "table" and itemOrName.Frame and sectItems[itemOrName.Frame] then
					return sectItems[itemOrName.Frame]
				end
				if type(itemOrName) == "string" then
					for _, entry in ipairs(sectItems) do
						if entry.Name and entry.Name:lower() == itemOrName:lower() then
							return entry
						end
					end
					local child = ScrollingFrame:FindFirstChild(itemOrName)
					if child and child:IsA("GuiObject") then
						return { Name = itemOrName, Frame = child, Object = sectItems[child] and sectItems[child].Object }
					end
				end
				if typeof and typeof(itemOrName) == "Instance" and itemOrName:IsA("GuiObject") then
					return { Name = itemOrName.Name, Frame = itemOrName }
				end

				-- Check global library items across all sections in the window
				if globalLibraryItems then
					if globalLibraryItems[itemOrName] then
						return globalLibraryItems[itemOrName]
					end
					if type(itemOrName) == "table" and itemOrName.Frame and globalLibraryItems[itemOrName.Frame] then
						return globalLibraryItems[itemOrName.Frame]
					end
					if type(itemOrName) == "string" then
						for key, entry in pairs(globalLibraryItems) do
							if type(key) == "string" and key:lower() == itemOrName:lower() then
								return entry
							end
							if type(entry) == "table" and entry.Name and entry.Name:lower() == itemOrName:lower() then
								return entry
							end
						end
					end
				end

				-- Check SaveManager objects as fallback
				if sm and sm.Objects and type(itemOrName) == "string" then
					local smEntry = sm.Objects[itemOrName]
					if smEntry and smEntry.Object then
						local obj = smEntry.Object
						local frame = obj.Frame or (sectItems[obj] and sectItems[obj].Frame) or (globalLibraryItems and globalLibraryItems[obj] and globalLibraryItems[obj].Frame)
						if frame then
							return { Name = itemOrName, Object = obj, Frame = frame }
						end
					end
				end

				return nil
			end

			function sect:SetDisplayOrder(first, second, third)
				local itemOrName, order
				if first == sect then
					itemOrName = second
					order = third
				else
					itemOrName = first
					order = second
				end
				if order == nil and tonumber(itemOrName) then
					local num = tonumber(itemOrName)
					section.LayoutOrder = math.floor(num)
					queueSectionScrollUpdate()
					return true
				end
				local entry = resolveSectItem(itemOrName)
				local num = tonumber(order)
				if entry and entry.Frame and num then
					entry.Frame.LayoutOrder = math.floor(num)
					queueSectionScrollUpdate()
					return true
				end
				return false
			end
			sect.SetLayoutOrder = sect.SetDisplayOrder
			sect.SetOrder = sect.SetDisplayOrder

			function sect:GetDisplayOrder(first, second)
				local itemOrName
				if first == sect then
					itemOrName = second
				else
					itemOrName = first
				end
				if itemOrName == nil then
					return section.LayoutOrder or 0
				end
				local entry = resolveSectItem(itemOrName)
				if entry and entry.Frame then
					return entry.Frame.LayoutOrder or 0
				end
				if type(itemOrName) == "table" and itemOrName.GetDisplayOrder and itemOrName ~= sect then
					local val = itemOrName:GetDisplayOrder()
					if tonumber(val) then return tonumber(val) end
				end
				return 0
			end
			sect.GetLayoutOrder = sect.GetDisplayOrder
			sect.GetOrder = sect.GetDisplayOrder

			function sect:GetItems()
				return sectItems
			end
			sect.Items = sectItems

			function sect:CreateButton(name, callback, orderOrOptions)
				local cb = callback
				local initialOrder = extractOrderFromOptions(orderOrOptions)
				if type(callback) == "table" then
					local opts = callback
					cb = opts.Callback or opts.callback
					initialOrder = initialOrder or extractOrderFromOptions(opts)
				end

				local Button = Instance.new("Frame")
				Button.Name = "Button"
				Button.BorderColor3 = Color3.new(0, 0, 0)
				Button.BorderSizePixel = 0
				Button.BackgroundTransparency = 1
				Button.Position = UDim2.new(0, 0, 0.08, 0)
				Button.BackgroundColor3 = Color3.new(1, 1, 1)
				Button.Parent = ScrollingFrame

				local TextButton = Instance.new("TextButton")
				TextButton.Name = "TextButton"
				TextButton.AnchorPoint = Vector2.new(0.5, 0.5)
				TextButton.Size = UDim2.new(0.82, 0, 0, 21)
				TextButton.BorderColor3 = Color3.new(0, 0, 0)
				TextButton.BorderSizePixel = 0
				TextButton.Position = UDim2.new(0.5, 0, 0.5, 0)
				TextButton.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				TextButton.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
				TextButton.TextColor3 = Color3.new(0.65, 0.65, 0.65)
				TextButton.Parent = Button
				TextButton.Text = name

				local ButtonSizeConstraint = Instance.new("UISizeConstraint")
				ButtonSizeConstraint.MaxSize = Vector2.new(224, 21)
				ButtonSizeConstraint.Parent = TextButton

				local padding = 4
				Button.Size = UDim2.new(1, 0, 0, TextButton.Size.Y.Offset + padding)

				local UIStroke = Instance.new("UIStroke")
				UIStroke.Name = "UIStroke"
				UIStroke.Color = Color3.fromRGB(41,42,42)
				UIStroke.Thickness = 1.4
				UIStroke.LineJoinMode = Enum.LineJoinMode.Miter
				UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				UIStroke.Parent = TextButton

				local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
				UITextSizeConstraint.Name = "UITextSizeConstraint"
				UITextSizeConstraint.MinTextSize = 14
				UITextSizeConstraint.Parent = TextButton

				TextButton.MouseButton1Click:Connect(function()
					if typeof(cb) == "function" then
						cb()
					end
				end)

				local buttonObj
				local function setButtonOrder(ord)
					local num = tonumber(ord)
					if num then
						Button.LayoutOrder = math.floor(num)
						queueSectionScrollUpdate()
					end
				end

				buttonObj = {
					Frame = Button,
					Instance = Button,
					TextButton = TextButton,
					GetDisplayOrder = function() return Button.LayoutOrder end,
					GetLayoutOrder = function() return Button.LayoutOrder end,
					GetOrder = function() return Button.LayoutOrder end,
					SetDisplayOrder = function(selfOrVal, val)
						local order = extractArg(selfOrVal, val, buttonObj)
						setButtonOrder(order)
					end,
					SetLayoutOrder = function(selfOrVal, val)
						local order = extractArg(selfOrVal, val, buttonObj)
						setButtonOrder(order)
					end,
					SetOrder = function(selfOrVal, val)
						local order = extractArg(selfOrVal, val, buttonObj)
						setButtonOrder(order)
					end,
					GetVisiblity = function() return Button.Visible end,
					GetVisibility = function() return Button.Visible end,
					SetVisiblity = function(selfOrVal, val)
						local bool = extractArg(selfOrVal, val, buttonObj)
						if type(bool) == "boolean" then
							Button.Visible = bool
							queueSectionScrollUpdate()
						end
					end,
					SetVisibility = function(selfOrVal, val)
						local bool = extractArg(selfOrVal, val, buttonObj)
						if type(bool) == "boolean" then
							Button.Visible = bool
							queueSectionScrollUpdate()
						end
					end,
				}

				setmetatable(buttonObj, {
					__index = function(self, key)
						if key == "LayoutOrder" or key == "DisplayOrder" or key == "Order" then
							return Button.LayoutOrder
						end
						local instVal = Button[key]
						if typeof(instVal) == "function" then
							return function(_, ...)
								return instVal(Button, ...)
							end
						end
						return instVal
					end,
					__newindex = function(self, key, value)
						if key == "LayoutOrder" or key == "DisplayOrder" or key == "Order" then
							setButtonOrder(value)
							return
						end
						pcall(function()
							Button[key] = value
						end)
					end
				})

				registerSectItem(name, buttonObj, Button, initialOrder)
				queueSectionScrollUpdate()
				return buttonObj
			end

	local function makeBevelGradient(baseColor)
		baseColor = typeof(baseColor) == "Color3" and baseColor or Color3.fromRGB(255, 255, 255)
		local topColor = Color3.new(
			math.clamp(baseColor.R * 1.35 + 0.05, 0, 1),
			math.clamp(baseColor.G * 1.35 + 0.05, 0, 1),
			math.clamp(baseColor.B * 1.35 + 0.05, 0, 1)
		)
		local botColor = Color3.new(
			math.clamp(baseColor.R * 0.68, 0, 1),
			math.clamp(baseColor.G * 0.68, 0, 1),
			math.clamp(baseColor.B * 0.68, 0, 1)
		)
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, topColor),
			ColorSequenceKeypoint.new(1.00, botColor)
		})
	end

	local function createColorPickerPopup(colorBttn, defaultColor, defaultAlpha, callback)
		local currentColor = typeof(defaultColor) == "Color3" and defaultColor or Color3.fromRGB(255, 255, 255)
		local currentAlpha = type(defaultAlpha) == "number" and math.clamp(defaultAlpha, 0, 1) or 1
		local currentHue, currentSat, currentVal = Color3.toHSV(currentColor)

		colorBttn.BackgroundColor3 = Color3.new(1, 1, 1)
		colorBttn.AutoButtonColor = false
		local colorBttnGrad = colorBttn:FindFirstChild("BevelGradient")
		if not colorBttnGrad then
			colorBttnGrad = Instance.new("UIGradient")
			colorBttnGrad.Name = "BevelGradient"
			colorBttnGrad.Rotation = 90
			colorBttnGrad.Parent = colorBttn
		end
		colorBttnGrad.Color = makeBevelGradient(currentColor)

		local ColorPickerFrame = Instance.new("Frame")
		ColorPickerFrame.Name = "ColorPickerFrame"
		ColorPickerFrame.Size = UDim2.new(0, 136, 0, 132)
		ColorPickerFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
		ColorPickerFrame.BorderSizePixel = 0
		ColorPickerFrame.Visible = false
		ColorPickerFrame.ZIndex = 80
		ColorPickerFrame.Parent = Main

		local cpStroke = Instance.new("UIStroke")
		cpStroke.Color = Color3.fromRGB(35, 35, 35)
		cpStroke.Thickness = 1
		cpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cpStroke.LineJoinMode = Enum.LineJoinMode.Miter
		cpStroke.Parent = ColorPickerFrame

		-- SV Palette Square (106 x 106)
		local svBox = Instance.new("Frame")
		svBox.Name = "SVBox"
		svBox.Size = UDim2.new(0, 106, 0, 106)
		svBox.Position = UDim2.new(0, 5, 0, 5)
		svBox.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
		svBox.BorderSizePixel = 0
		svBox.ZIndex = 81
		svBox.Parent = ColorPickerFrame

		local svStroke = Instance.new("UIStroke")
		svStroke.Color = Color3.fromRGB(15, 15, 15)
		svStroke.Thickness = 1
		svStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		svStroke.LineJoinMode = Enum.LineJoinMode.Miter
		svStroke.Parent = svBox

		-- Saturation overlay (white -> transparent)
		local satFrame = Instance.new("Frame")
		satFrame.Name = "SatOverlay"
		satFrame.Size = UDim2.new(1, 0, 1, 0)
		satFrame.BackgroundColor3 = Color3.new(1, 1, 1)
		satFrame.BorderSizePixel = 0
		satFrame.ZIndex = 82
		satFrame.Parent = svBox

		local satGrad = Instance.new("UIGradient")
		satGrad.Color = ColorSequence.new(Color3.new(1, 1, 1))
		satGrad.Rotation = 0
		satGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1)
		})
		satGrad.Parent = satFrame

		-- Value overlay (transparent -> black)
		local valFrame = Instance.new("Frame")
		valFrame.Name = "ValOverlay"
		valFrame.Size = UDim2.new(1, 0, 1, 0)
		valFrame.BackgroundColor3 = Color3.new(0, 0, 0)
		valFrame.BorderSizePixel = 0
		valFrame.ZIndex = 83
		valFrame.Parent = svBox

		local valGrad = Instance.new("UIGradient")
		valGrad.Color = ColorSequence.new(Color3.new(0, 0, 0))
		valGrad.Rotation = 90
		valGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0)
		})
		valGrad.Parent = valFrame

		-- SV Cursor (circle indicator ring matching screenshot)
		local svCursor = Instance.new("Frame")
		svCursor.Name = "SVCursor"
		svCursor.Size = UDim2.new(0, 6, 0, 6)
		svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
		svCursor.Position = UDim2.new(currentSat, 0, 1 - currentVal, 0)
		svCursor.BackgroundTransparency = 1
		svCursor.BorderSizePixel = 0
		svCursor.ZIndex = 86
		svCursor.Parent = svBox

		local svCursorCorner = Instance.new("UICorner")
		svCursorCorner.CornerRadius = UDim.new(1, 0)
		svCursorCorner.Parent = svCursor

		local svCursorStroke = Instance.new("UIStroke")
		svCursorStroke.Color = Color3.fromRGB(15, 15, 15)
		svCursorStroke.Thickness = 1.2
		svCursorStroke.Parent = svCursor

		-- Hue Bar (15 x 106)
		local hueBar = Instance.new("Frame")
		hueBar.Name = "HueBar"
		hueBar.Size = UDim2.new(0, 15, 0, 106)
		hueBar.Position = UDim2.new(0, 116, 0, 5)
		hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
		hueBar.BorderSizePixel = 0
		hueBar.ZIndex = 81
		hueBar.Parent = ColorPickerFrame

		local hueStroke = Instance.new("UIStroke")
		hueStroke.Color = Color3.fromRGB(15, 15, 15)
		hueStroke.Thickness = 1
		hueStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		hueStroke.LineJoinMode = Enum.LineJoinMode.Miter
		hueStroke.Parent = hueBar

		local hueGrad = Instance.new("UIGradient")
		hueGrad.Rotation = 90
		hueGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
		})
		hueGrad.Parent = hueBar

		-- Hue Cursor (horizontal line across Hue bar)
		local hueCursor = Instance.new("Frame")
		hueCursor.Name = "HueCursor"
		hueCursor.Size = UDim2.new(1, 0, 0, 2)
		hueCursor.AnchorPoint = Vector2.new(0, 0.5)
		hueCursor.Position = UDim2.new(0, 0, currentHue, 0)
		hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
		hueCursor.BorderSizePixel = 0
		hueCursor.ZIndex = 85
		hueCursor.Parent = hueBar

		local hueCursorStroke = Instance.new("UIStroke")
		hueCursorStroke.Color = Color3.fromRGB(15, 15, 15)
		hueCursorStroke.Thickness = 1
		hueCursorStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		hueCursorStroke.Parent = hueCursor

		-- Alpha Bar (106 x 11)
		local alphaBar = Instance.new("Frame")
		alphaBar.Name = "AlphaBar"
		alphaBar.Size = UDim2.new(0, 106, 0, 11)
		alphaBar.Position = UDim2.new(0, 5, 0, 116)
		alphaBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
		alphaBar.BorderSizePixel = 0
		alphaBar.ZIndex = 81
		alphaBar.Parent = ColorPickerFrame

		local alphaStroke = Instance.new("UIStroke")
		alphaStroke.Color = Color3.fromRGB(15, 15, 15)
		alphaStroke.Thickness = 1
		alphaStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		alphaStroke.LineJoinMode = Enum.LineJoinMode.Miter
		alphaStroke.Parent = alphaBar

		local alphaFill = Instance.new("Frame")
		alphaFill.Name = "AlphaFill"
		alphaFill.Size = UDim2.new(1, 0, 1, 0)
		alphaFill.BackgroundColor3 = Color3.new(1, 1, 1)
		alphaFill.BorderSizePixel = 0
		alphaFill.ZIndex = 82
		alphaFill.Parent = alphaBar

		local alphaGrad = Instance.new("UIGradient")
		alphaGrad.Rotation = 0
		alphaGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(1.00, currentColor)
		})
		alphaGrad.Parent = alphaFill

		-- Alpha Cursor (vertical tick cursor)
		local alphaCursor = Instance.new("Frame")
		alphaCursor.Name = "AlphaCursor"
		alphaCursor.Size = UDim2.new(0, 2, 1, 0)
		alphaCursor.AnchorPoint = Vector2.new(0.5, 0)
		alphaCursor.Position = UDim2.new(currentAlpha, 0, 0, 0)
		alphaCursor.BackgroundColor3 = Color3.new(1, 1, 1)
		alphaCursor.BorderSizePixel = 0
		alphaCursor.ZIndex = 85
		alphaCursor.Parent = alphaBar

		local alphaCursorStroke = Instance.new("UIStroke")
		alphaCursorStroke.Color = Color3.fromRGB(15, 15, 15)
		alphaCursorStroke.Thickness = 1
		alphaCursorStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		alphaCursorStroke.Parent = alphaCursor

		-- Color Preview Box (15 x 11)
		local previewBox = Instance.new("Frame")
		previewBox.Name = "PreviewBox"
		previewBox.Size = UDim2.new(0, 15, 0, 11)
		previewBox.Position = UDim2.new(0, 116, 0, 116)
		previewBox.BackgroundColor3 = Color3.new(1, 1, 1)
		previewBox.BorderSizePixel = 0
		previewBox.ZIndex = 82
		previewBox.Parent = ColorPickerFrame

		local previewGrad = Instance.new("UIGradient")
		previewGrad.Name = "BevelGradient"
		previewGrad.Rotation = 90
		previewGrad.Color = makeBevelGradient(currentColor)
		previewGrad.Parent = previewBox

		local previewStroke = Instance.new("UIStroke")
		previewStroke.Color = Color3.fromRGB(15, 15, 15)
		previewStroke.Thickness = 1
		previewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		previewStroke.LineJoinMode = Enum.LineJoinMode.Miter
		previewStroke.Parent = previewBox

		local function applyColor(fireCb)
			local col = Color3.fromHSV(currentHue, currentSat, currentVal)
			currentColor = col
			svBox.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
			svCursor.Position = UDim2.new(currentSat, 0, 1 - currentVal, 0)
			hueCursor.Position = UDim2.new(0, 0, currentHue, 0)
			alphaCursor.Position = UDim2.new(currentAlpha, 0, 0, 0)
			alphaGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 0, 0)),
				ColorSequenceKeypoint.new(1.00, currentColor)
			})
			previewBox.BackgroundColor3 = Color3.new(1, 1, 1)
			previewGrad.Color = makeBevelGradient(currentColor)
			colorBttn.BackgroundColor3 = Color3.new(1, 1, 1)
			colorBttnGrad.Color = makeBevelGradient(currentColor)
			if fireCb ~= false and callback then
				pcall(callback, currentColor, currentAlpha)
			end
		end

		local function setColor(col, alpha, fireCb)
			if typeof(col) == "Color3" then
				currentColor = col
				currentHue, currentSat, currentVal = Color3.toHSV(col)
			end
			if type(alpha) == "number" then
				currentAlpha = math.clamp(alpha, 0, 1)
			end
			applyColor(fireCb)
		end

		local draggingSV = false
		local draggingHue = false
		local draggingAlpha = false

		local function updateSV(posX, posY)
			local minX = svBox.AbsolutePosition.X
			local maxX = minX + svBox.AbsoluteSize.X
			local minY = svBox.AbsolutePosition.Y
			local maxY = minY + svBox.AbsoluteSize.Y
			currentSat = math.clamp((posX - minX) / (maxX - minX), 0, 1)
			currentVal = 1 - math.clamp((posY - minY) / (maxY - minY), 0, 1)
			applyColor(true)
		end

		local function updateHue(posY)
			local minY = hueBar.AbsolutePosition.Y
			local maxY = minY + hueBar.AbsoluteSize.Y
			currentHue = math.clamp((posY - minY) / (maxY - minY), 0, 1)
			applyColor(true)
		end

		local function updateAlpha(posX)
			local minX = alphaBar.AbsolutePosition.X
			local maxX = minX + alphaBar.AbsoluteSize.X
			currentAlpha = math.clamp((posX - minX) / (maxX - minX), 0, 1)
			applyColor(true)
		end

		svBox.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				draggingSV = true
				updateSV(input.Position.X, input.Position.Y)
			end
		end)

		hueBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				draggingHue = true
				updateHue(input.Position.Y)
			end
		end)

		alphaBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				draggingAlpha = true
				updateAlpha(input.Position.X)
			end
		end)

		UIS.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				if draggingSV then
					updateSV(input.Position.X, input.Position.Y)
				elseif draggingHue then
					updateHue(input.Position.Y)
				elseif draggingAlpha then
					updateAlpha(input.Position.X)
				end
			end
		end)

		UIS.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				draggingSV = false
				draggingHue = false
				draggingAlpha = false
			end
		end)

		local function updatePosition()
			if not ColorPickerFrame.Visible then return end
			local scale = (Ui_Scale and Ui_Scale.Scale) or 1
			local bttnPos = colorBttn.AbsolutePosition
			local mainPos = Main.AbsolutePosition
			local bttnSize = colorBttn.AbsoluteSize
			local relX = (bttnPos.X - mainPos.X) / scale
			local relY = (bttnPos.Y - mainPos.Y) / scale
			local pickerW = 136
			local pickerH = 132

			local posX = relX + (bttnSize.X / scale) - pickerW
			local posY = relY + (bttnSize.Y / scale) + 4

			local maxMainY = Main.AbsoluteSize.Y / scale
			if posY + pickerH > maxMainY - 10 then
				posY = relY - pickerH - 4
			end
			if posX < 6 then
				posX = 6
			end

			ColorPickerFrame.Position = UDim2.new(0, math.floor(posX), 0, math.floor(posY))
		end

		local justOpenedTick = 0

		local function openPicker()
			ColorPickerFrame.Visible = true
			justOpenedTick = tick()
			updatePosition()
		end

		local function closePicker()
			ColorPickerFrame.Visible = false
			draggingSV = false
			draggingHue = false
			draggingAlpha = false
		end

		local function togglePicker()
			if ColorPickerFrame.Visible then
				closePicker()
			else
				openPicker()
			end
		end

		colorBttn.MouseButton1Click:Connect(togglePicker)

		if ScrollingFrame then
			ScrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
				if ColorPickerFrame.Visible then
					local bttnPos = colorBttn.AbsolutePosition
					local sfTop = ScrollingFrame.AbsolutePosition.Y
					local sfBot = sfTop + ScrollingFrame.AbsoluteSize.Y
					if (bttnPos.Y + colorBttn.AbsoluteSize.Y < sfTop) or (bttnPos.Y > sfBot) then
						ColorPickerFrame.Visible = false
					else
						updatePosition()
					end
				end
			end)
		end

		UIS.InputBegan:Connect(function(input)
			if not ColorPickerFrame.Visible then return end
			if tick() - justOpenedTick < 0.15 then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local pos = input.Position
				local cpPos = ColorPickerFrame.AbsolutePosition
				local cpSize = ColorPickerFrame.AbsoluteSize
				local inCP = pos.X >= cpPos.X and pos.X <= cpPos.X + cpSize.X and pos.Y >= cpPos.Y and pos.Y <= cpPos.Y + cpSize.Y

				local bPos = colorBttn.AbsolutePosition
				local bSize = colorBttn.AbsoluteSize
				local inBttn = pos.X >= bPos.X and pos.X <= bPos.X + bSize.X and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSize.Y

				if not inCP and not inBttn then
					closePicker()
				end
			end
		end)

		applyColor(false)

		return {
			Get = function() return currentColor end,
			Set = function(col, alpha, fireCb) setColor(col, alpha, fireCb) end,
			GetAlpha = function() return currentAlpha end,
			SetAlpha = function(alpha, fireCb)
				if type(alpha) == "number" then
					currentAlpha = math.clamp(alpha, 0, 1)
					applyColor(fireCb)
				end
			end,
			SetCallback = function(fn) callback = fn end,
			Close = closePicker,
			Open = openPicker,
			Toggle = togglePicker,
			Frame = ColorPickerFrame
		}
	end

function sect:CreateToggle(Name, Title, Default, binded, bind, callback, orderOrOptions)
	local initialOrder = extractOrderFromOptions(orderOrOptions)
	if initialOrder == nil and type(Title) == "table" then
		local opts = Title
		initialOrder = extractOrderFromOptions(opts)
		Title = opts.Title ~= nil and opts.Title or (opts.Name or Name)
		Default = opts.Default ~= nil and opts.Default or opts.default
		binded = opts.binded ~= nil and opts.binded or opts.Binded
		bind = opts.bind or opts.Bind
		callback = opts.callback or opts.Callback
	elseif initialOrder == nil and type(Default) == "table" then
		local opts = Default
		initialOrder = extractOrderFromOptions(opts)
		Title = opts.Title ~= nil and opts.Title or (opts.Name or Title or Name)
		Default = opts.Default ~= nil and opts.Default or opts.default
		binded = opts.binded ~= nil and opts.binded or opts.Binded
		bind = opts.bind or opts.Bind
		callback = opts.callback or opts.Callback
	elseif initialOrder == nil and type(binded) == "table" then
		initialOrder = extractOrderFromOptions(binded)
	elseif initialOrder == nil and type(bind) == "table" then
		initialOrder = extractOrderFromOptions(bind)
	elseif initialOrder == nil and type(callback) == "table" then
		local opts = callback
		initialOrder = extractOrderFromOptions(opts)
		callback = opts.callback or opts.Callback
	end

	local function toToggleState(value)
		if type(value) == "boolean" then
			return value
		end

		if type(value) == "string" then
			local lowered = value:lower():gsub("^%s+", ""):gsub("%s+$", "")
			if lowered == "true" then
				return true
			end
			if lowered == "false" then
				return false
			end
		end

		return nil
	end

	Default = toToggleState(Default) or false
	local state = Default
	local hasBind = binded == true
	local currentBind = bind or nil
	local bindMode = "Toggle"
	local hasColor = false
	local colorPickerObj = nil

	local UIS = game:GetService("UserInputService")

	local Toggle = Instance.new("Frame")
	Toggle.Name = "Toggle"
	Toggle.ZIndex = 6
	Toggle.Size = UDim2.new(1, 0, 0, 18)
	Toggle.BorderSizePixel = 0
	Toggle.BackgroundTransparency = 1
	Toggle.Parent = ScrollingFrame

	local ToggleBttn = Instance.new("TextButton")
	ToggleBttn.Name = "ToggleBttn"
	ToggleBttn.Size = UDim2.new(0, 12, 0, 12)
	ToggleBttn.Position = UDim2.new(0.05, 0, 0.5, -6)
	ToggleBttn.BackgroundColor3 = state and Color3.new(1, 1, 1) or Color3.fromRGB(17, 17, 17)
	ToggleBttn.AutoButtonColor = false
	ToggleBttn.BorderSizePixel = 0
	ToggleBttn.Text = ""
	ToggleBttn.Parent = Toggle

	local toggleGrad = Instance.new("UIGradient")
	toggleGrad.Name = "BevelGradient"
	toggleGrad.Rotation = 90
	toggleGrad.Color = makeBevelGradient(accent_color)
	toggleGrad.Enabled = state
	toggleGrad.Parent = ToggleBttn

	local UIStroke = Instance.new("UIStroke")
	UIStroke.Color = Color3.fromRGB(41,42,42)
	UIStroke.Thickness = 1.4
	UIStroke.Parent = ToggleBttn
	UIStroke.LineJoinMode = Enum.LineJoinMode.Miter
	UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local ColorBttn = Instance.new("TextButton")
	ColorBttn.Name = "ColorBttn"
	ColorBttn.AutoButtonColor = false
	ColorBttn.Size = UDim2.new(0, 19, 0, 12)
	ColorBttn.AnchorPoint = Vector2.new(1, 0.5)
	ColorBttn.Position = UDim2.new(1, -12, 0.5, 0)
	ColorBttn.BorderSizePixel = 0
	ColorBttn.BackgroundColor3 = Color3.new(1, 1, 1)
	ColorBttn.TextColor3 = Color3.new(0, 0, 0)
	ColorBttn.Text = " "
	ColorBttn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	ColorBttn.Parent = Toggle
	ColorBttn.Visible = false

	local colorBttnGrad = Instance.new("UIGradient")
	colorBttnGrad.Name = "BevelGradient"
	colorBttnGrad.Rotation = 90
	colorBttnGrad.Color = makeBevelGradient(Color3.fromRGB(255, 255, 255))
	colorBttnGrad.Parent = ColorBttn

	local colorBttnUIStroke = Instance.new("UIStroke")
	colorBttnUIStroke.Name = "UIStroke"
	colorBttnUIStroke.Color = Color3.new(0, 0, 0)
	colorBttnUIStroke.Thickness = 1.4
	colorBttnUIStroke.LineJoinMode = Enum.LineJoinMode.Miter
	colorBttnUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	colorBttnUIStroke.Parent = ColorBttn

	local hasTitle = Title ~= nil and Title ~= ""
	local TextLabel
	if hasTitle then
		TextLabel = Instance.new("TextLabel")
		TextLabel.Size = UDim2.new(0.95, -75, 1, 0)
		TextLabel.BackgroundTransparency = 1
		TextLabel.Position = UDim2.new(0.05, 20, 0, 0)
		TextLabel.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium)
		TextLabel.TextColor3 = Color3.new(0.65, 0.65, 0.65)
		TextLabel.Text = Title
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left
		TextLabel.TextTruncate = Enum.TextTruncate.AtEnd
		TextLabel.Parent = Toggle

		local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
		UITextSizeConstraint.MinTextSize = 14
		UITextSizeConstraint.Parent = TextLabel
	end

	local Keybind = Instance.new("TextButton")
	Keybind.Name = "Keybind"
	Keybind.AnchorPoint = Vector2.new(1, 0.5)
	Keybind.Size = UDim2.new(0, 48, 1, 0)
	Keybind.BorderSizePixel = 0
	Keybind.BackgroundTransparency = 1
	Keybind.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium)
	Keybind.TextColor3 = Color3.new(0.65, 0.65, 0.65)
	Keybind.Text = currentBind and "["..currentBind.."]" or ""
	Keybind.TextXAlignment = Enum.TextXAlignment.Right
	Keybind.Parent = Toggle
	Keybind.Visible = hasBind

	local s = Instance.new("UITextSizeConstraint")
	s.MinTextSize = 14
	s.Parent = Keybind

	local Popup = Instance.new("Frame")
	Popup.Size = UDim2.new(0, 80, 0, 66)
	Popup.Position = UDim2.new(-0.3, -80, 0, 0)
	Popup.BackgroundColor3 = Color3.fromRGB(30,30,30)
	Popup.BorderSizePixel = 0
	Popup.Visible = false
	Popup.Parent = Keybind
	Popup.ZIndex = 8

	local layout = Instance.new("UIListLayout")
	layout.Parent = Popup
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	local function createOption(text)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 22)
		btn.BackgroundTransparency = 1
		btn.Text = text
		btn.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium)
		btn.TextSize = 14
		btn.TextColor3 = text == bindMode and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)
		btn.Parent = Popup
		btn.ZIndex = Popup.ZIndex + 1
		btn.MouseButton1Click:Connect(function()
			bindMode = text
			for _, c in ipairs(Popup:GetChildren()) do
				if c:IsA("TextButton") then
					c.TextColor3 = c.Text == bindMode and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)
				end
			end
			Popup.Visible = false
		end)
	end

	createOption("Always")
	createOption("Toggle")
	createOption("Hold")

	local waitingForKey = false

	Keybind.MouseButton1Click:Connect(function()
		Keybind.Text = "[Press Key]"
		waitingForKey = true
	end)

	Keybind.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			Popup.Visible = not Popup.Visible
		end
	end)

	UIS.InputBegan:Connect(function(input, gameProcessed)
		if waitingForKey and not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
			currentBind = input.KeyCode.Name
			Keybind.Text = "["..currentBind.."]"
			waitingForKey = false
		end
	end)

	local function updateLayout()
		ColorBttn.Visible = hasColor
		Keybind.Visible = hasBind
		local rightOffset = 16
		if hasColor and hasBind then
			Keybind.Position = UDim2.new(1, -35, 0.5, 0)
			rightOffset = 88
		elseif hasColor then
			rightOffset = 36
		elseif hasBind then
			Keybind.Position = UDim2.new(1, -12, 0.5, 0)
			rightOffset = 64
		end
		if TextLabel then
			TextLabel.Size = UDim2.new(0.95, -(20 + rightOffset), 1, 0)
		end
	end
	updateLayout()

	local function setState(value, fireCallback)
		local parsed = toToggleState(value)
		if parsed == nil then
			return
		end

		state = parsed
		if state then
			ToggleBttn.BackgroundColor3 = Color3.new(1, 1, 1)
			toggleGrad.Color = makeBevelGradient(accent_color)
			toggleGrad.Enabled = true
		else
			ToggleBttn.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
			toggleGrad.Enabled = false
		end
		if fireCallback ~= false and callback then
			pcall(callback, state)
		end
	end

	ToggleBttn.MouseButton1Click:Connect(function()
		setState(not state)
	end)

	local toggleObj
	toggleObj = {
		Get = function() return state end,
		GetValue = function() return state end,
		Set = function(selfOrVal, val)
			local value = extractArg(selfOrVal, val, toggleObj)
			setState(value)
		end,
		SetValue = function(selfOrVal, val)
			local value = extractArg(selfOrVal, val, toggleObj)
			setState(value)
		end,
		Toggle = function()
			setState(not state)
		end,
		UpdateColor = function()
			if toggleGrad and state then
				toggleGrad.Color = makeBevelGradient(accent_color)
			end
		end,
		GetBindedState = function() return hasBind end,
		SetBindedState = function(selfOrVal, val)
			local value = extractArg(selfOrVal, val, toggleObj)
			local parsed = toToggleState(value)
			if parsed == nil then
				return
			end

			hasBind = parsed
			updateLayout()
		end,
		GetBind = function() return currentBind end,
		SetBind = function(selfOrVal, val)
			local newBind = extractArg(selfOrVal, val, toggleObj)
			if newBind ~= nil and type(newBind) ~= "string" then
				return
			end

			currentBind = newBind
			if Keybind then Keybind.Text = currentBind and "["..currentBind.."]" or "" end
		end,
		GetBindMode = function() return bindMode end,
		SetBindMode = function(selfOrVal, val)
			local mode = extractArg(selfOrVal, val, toggleObj)
			if mode ~= "Always" and mode ~= "Toggle" and mode ~= "Hold" then
				mode = "Toggle"
			end
			bindMode = mode
			if Popup then
				for _, c in ipairs(Popup:GetChildren()) do
					if c:IsA("TextButton") then
						c.TextColor3 = c.Text == bindMode and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)
					end
				end
			end
		end,
		GetColor = function()
			return colorPickerObj and colorPickerObj.Get() or nil
		end,
		GetValueColor = function()
			return colorPickerObj and colorPickerObj.Get() or nil
		end,
		SetColor = function(selfOrVal, val, val2)
			if colorPickerObj then
				local col = extractArg(selfOrVal, val, toggleObj)
				local a = (selfOrVal == toggleObj) and val2 or nil
				colorPickerObj.Set(col, a, true)
			end
		end,
		GetAlpha = function()
			return colorPickerObj and colorPickerObj.GetAlpha() or 1
		end,
		SetAlpha = function(selfOrVal, val)
			if colorPickerObj then
				local a = extractArg(selfOrVal, val, toggleObj)
				colorPickerObj.SetAlpha(a, true)
			end
		end,
		GetColorState = function()
			return hasColor
		end,
		SetColorState = function(selfOrVal, val)
			local bool = extractArg(selfOrVal, val, toggleObj)
			local parsed = toToggleState(bool)
			if parsed ~= nil then
				hasColor = parsed
				updateLayout()
			end
		end,
		AddColorPicker = function(selfOrArg1, ...)
			local args = { ... }
			local a1, a2, a3
			if selfOrArg1 == toggleObj then
				a1 = args[1]
				a2 = args[2]
				a3 = args[3]
			else
				a1 = selfOrArg1
				a2 = args[1]
				a3 = args[2]
			end

			local cpName = Name .. "Color"
			local defColor = Color3.fromRGB(255, 255, 255)
			local cb = nil

			if type(a1) == "string" then
				cpName = a1
				if typeof(a2) == "Color3" then
					defColor = a2
					cb = a3
				elseif type(a2) == "table" then
					defColor = a2.Default or a2.Color or a2.default or defColor
					cb = a2.Callback or a2.callback or a3
				elseif type(a2) == "function" then
					cb = a2
				end
			elseif typeof(a1) == "Color3" then
				defColor = a1
				cb = a2
			elseif type(a1) == "table" then
				cpName = a1.Name or a1.name or cpName
				defColor = a1.Default or a1.Color or a1.default or defColor
				cb = a1.Callback or a1.callback or a2
			elseif type(a1) == "function" then
				cb = a1
			end

			hasColor = true
			if not colorPickerObj then
				colorPickerObj = createColorPickerPopup(ColorBttn, defColor, 1, function(col, a)
					if cb then
						pcall(cb, col, a)
					end
				end)
			else
				colorPickerObj.Set(defColor, 1, false)
				if cb then
					colorPickerObj.SetCallback(cb)
				end
			end

			updateLayout()
			sm:Register(cpName, colorPickerObj, "ColorPicker")
			return colorPickerObj
		end,
		CreateColorPicker = function(selfOrArg1, ...)
			return toggleObj.AddColorPicker(selfOrArg1, ...)
		end,
		GetVisiblity = function()
			return Toggle.Visible
		end,
		GetVisibility = function()
			return Toggle.Visible
		end,
		SetVisiblity = function(selfOrVal, val)
			local bool = extractArg(selfOrVal, val, toggleObj)
			if type(bool) == "boolean" then
				Toggle.Visible = bool
				queueSectionScrollUpdate()
			end
		end,
		SetVisibility = function(selfOrVal, val)
			local bool = extractArg(selfOrVal, val, toggleObj)
			if type(bool) == "boolean" then
				Toggle.Visible = bool
				queueSectionScrollUpdate()
			end
		end,
		GetDisplayOrder = function()
			return Toggle.LayoutOrder
		end,
		GetLayoutOrder = function()
			return Toggle.LayoutOrder
		end,
		GetOrder = function()
			return Toggle.LayoutOrder
		end,
		SetDisplayOrder = function(selfOrVal, val)
			local order = extractArg(selfOrVal, val, toggleObj)
			local num = tonumber(order)
			if num then
				Toggle.LayoutOrder = math.floor(num)
				queueSectionScrollUpdate()
			end
		end,
		SetLayoutOrder = function(selfOrVal, val)
			local order = extractArg(selfOrVal, val, toggleObj)
			local num = tonumber(order)
			if num then
				Toggle.LayoutOrder = math.floor(num)
				queueSectionScrollUpdate()
			end
		end,
		SetOrder = function(selfOrVal, val)
			local order = extractArg(selfOrVal, val, toggleObj)
			local num = tonumber(order)
			if num then
				Toggle.LayoutOrder = math.floor(num)
				queueSectionScrollUpdate()
			end
		end
	}

	registerSectItem(Name, toggleObj, Toggle, initialOrder)
	applyOrderMethods(toggleObj, Toggle)
	sm:Register(Name, toggleObj, "Toggle")
	queueSectionScrollUpdate()
	return toggleObj
end

function sect:CreateColorPicker(Name, Title, DefaultColor, Callback, orderOrOptions)
	local initialOrder = extractOrderFromOptions(orderOrOptions)
	if initialOrder == nil and type(Title) == "table" then
		local opts = Title
		initialOrder = extractOrderFromOptions(opts)
		Title = opts.Title ~= nil and opts.Title or (opts.Name or Name)
		DefaultColor = opts.Default or opts.Color or opts.defaultColor or DefaultColor
		Callback = opts.Callback or opts.callback or Callback
	elseif initialOrder == nil and type(Callback) == "table" then
		local opts = Callback
		initialOrder = extractOrderFromOptions(opts)
		Callback = opts.Callback or opts.callback
	end

	local ColorPickerRow = Instance.new("Frame")
	ColorPickerRow.Name = "ColorPickerRow"
	ColorPickerRow.ZIndex = 6
	ColorPickerRow.Size = UDim2.new(1, 0, 0, 18)
	ColorPickerRow.BorderSizePixel = 0
	ColorPickerRow.BackgroundTransparency = 1
	ColorPickerRow.Parent = ScrollingFrame

	local hasTitle = Title ~= nil and Title ~= ""
	if hasTitle then
		local TextLabel = Instance.new("TextLabel")
		TextLabel.Size = UDim2.new(1, -35, 1, 0)
		TextLabel.BackgroundTransparency = 1
		TextLabel.Position = UDim2.new(0.05, 0, 0, 0)
		TextLabel.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium)
		TextLabel.TextColor3 = Color3.new(0.65, 0.65, 0.65)
		TextLabel.Text = Title or Name
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left
		TextLabel.Parent = ColorPickerRow

		local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
		UITextSizeConstraint.MinTextSize = 14
		UITextSizeConstraint.Parent = TextLabel
	end

	local ColorBttn = Instance.new("TextButton")
	ColorBttn.Name = "ColorBttn"
	ColorBttn.AutoButtonColor = false
	ColorBttn.Size = UDim2.new(0, 19, 0, 12)
	ColorBttn.AnchorPoint = Vector2.new(1, 0.5)
	ColorBttn.Position = UDim2.new(1, -12, 0.5, 0)
	ColorBttn.BorderSizePixel = 0
	ColorBttn.BackgroundColor3 = Color3.new(1, 1, 1)
	ColorBttn.Text = " "
	ColorBttn.Parent = ColorPickerRow

	local colorBttnUIStroke = Instance.new("UIStroke")
	colorBttnUIStroke.Name = "UIStroke"
	colorBttnUIStroke.Color = Color3.new(0, 0, 0)
	colorBttnUIStroke.Thickness = 1.4
	colorBttnUIStroke.LineJoinMode = Enum.LineJoinMode.Miter
	colorBttnUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	colorBttnUIStroke.Parent = ColorBttn

	local colorObj = createColorPickerPopup(ColorBttn, DefaultColor, 1, Callback)

	local pickerObj
	pickerObj = {
		Get = function() return colorObj.Get() end,
		GetValue = function() return colorObj.Get() end,
		Set = function(selfOrVal, val, val2)
			local c = extractArg(selfOrVal, val, pickerObj)
			local a = (selfOrVal == pickerObj) and val2 or nil
			colorObj.Set(c, a, true)
		end,
		SetValue = function(selfOrVal, val, val2)
			local c = extractArg(selfOrVal, val, pickerObj)
			local a = (selfOrVal == pickerObj) and val2 or nil
			colorObj.Set(c, a, true)
		end,
		GetAlpha = function() return colorObj.GetAlpha() end,
		SetAlpha = function(selfOrVal, val)
			local a = extractArg(selfOrVal, val, pickerObj)
			colorObj.SetAlpha(a, true)
		end,
		GetVisiblity = function() return ColorPickerRow.Visible end,
		GetVisibility = function() return ColorPickerRow.Visible end,
		SetVisiblity = function(selfOrVal, val)
			local bool = extractArg(selfOrVal, val, pickerObj)
			if type(bool) == "boolean" then
				ColorPickerRow.Visible = bool
				queueSectionScrollUpdate()
			end
		end,
		SetVisibility = function(selfOrVal, val)
			local bool = extractArg(selfOrVal, val, pickerObj)
			if type(bool) == "boolean" then
				ColorPickerRow.Visible = bool
				queueSectionScrollUpdate()
			end
		end,
		GetDisplayOrder = function() return ColorPickerRow.LayoutOrder end,
		GetLayoutOrder = function() return ColorPickerRow.LayoutOrder end,
		GetOrder = function() return ColorPickerRow.LayoutOrder end,
		SetDisplayOrder = function(selfOrVal, val)
			local order = extractArg(selfOrVal, val, pickerObj)
			local num = tonumber(order)
			if num then
				ColorPickerRow.LayoutOrder = math.floor(num)
				queueSectionScrollUpdate()
			end
		end,
		SetLayoutOrder = function(selfOrVal, val)
			local order = extractArg(selfOrVal, val, pickerObj)
			local num = tonumber(order)
			if num then
				ColorPickerRow.LayoutOrder = math.floor(num)
				queueSectionScrollUpdate()
			end
		end,
		SetOrder = function(selfOrVal, val)
			local order = extractArg(selfOrVal, val, pickerObj)
			local num = tonumber(order)
			if num then
				ColorPickerRow.LayoutOrder = math.floor(num)
				queueSectionScrollUpdate()
			end
		end
	}

	registerSectItem(Name, pickerObj, ColorPickerRow, initialOrder)
	applyOrderMethods(pickerObj, ColorPickerRow)
	sm:Register(Name, pickerObj, "ColorPicker")
	queueSectionScrollUpdate()
	return pickerObj
end
			function sect:CreateSlider(name, options)
				options = options or {}
				local initialOrder = extractOrderFromOptions(options)

				local title = options.Title or options.title or ""
				local default = options.Default or 0
				local Min = options.Min or 0
				local Max = options.Max or 100
				local Rounding = options.Rounding or 1
				local Suffix = options.Suffix or " "
				local callback = options.callback or function() end

				local UIS = game:GetService("UserInputService")
				local TweenService = game:GetService("TweenService")

				local hasTitle = title ~= "" and title ~= nil

				local Slider = Instance.new("Frame")
				Slider.Name = "Slider"
				Slider.Size = UDim2.new(1, 0, 0, hasTitle and 42 or 32)
				Slider.BorderColor3 = Color3.new(0, 0, 0)
				Slider.BorderSizePixel = 0
				Slider.BackgroundTransparency = 1
				Slider.Position = UDim2.new(0, 0, 0, 0)
				Slider.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				Slider.Parent = ScrollingFrame
				Slider.Visible = true

				if hasTitle then
					local TextLabel_4 = Instance.new("TextLabel")
					TextLabel_4.Name = "TextLabel"
					TextLabel_4.AnchorPoint = Vector2.new(0.5, 0)
					TextLabel_4.Size = UDim2.new(0.82, 0, 0, 16)
					TextLabel_4.BorderColor3 = Color3.new(0, 0, 0)
					TextLabel_4.BorderSizePixel = 0
					TextLabel_4.BackgroundTransparency = 1
					TextLabel_4.Position = UDim2.new(0.5, 0, 0, 1)
					TextLabel_4.BackgroundColor3 = Color3.new(1, 1, 1)
					TextLabel_4.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
					TextLabel_4.TextColor3 = Color3.new(0.65, 0.65, 0.65)
					TextLabel_4.Text = title
					TextLabel_4.TextXAlignment = Enum.TextXAlignment.Left
					TextLabel_4.Parent = Slider

					local SliderTitleConstraint = Instance.new("UISizeConstraint")
					SliderTitleConstraint.MaxSize = Vector2.new(224, 16)
					SliderTitleConstraint.Parent = TextLabel_4

					local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
					UITextSizeConstraint.Name = "UITextSizeConstraint"
					UITextSizeConstraint.MinTextSize = 14
					UITextSizeConstraint.Parent = TextLabel_4
				end

				local SliderBarFrame = Instance.new("Frame")
				SliderBarFrame.Name = "SliderBarFrame"
				SliderBarFrame.AnchorPoint = Vector2.new(0.5, 0)
				SliderBarFrame.Size = UDim2.new(0.82, 0, 0, 14)
				SliderBarFrame.Position = hasTitle and UDim2.new(0.5, 0, 0, 20) or UDim2.new(0.5, 0, 0, 6)
				SliderBarFrame.BackgroundTransparency = 1
				SliderBarFrame.BorderSizePixel = 0
				SliderBarFrame.Parent = Slider

				local SliderBarFrameConstraint = Instance.new("UISizeConstraint")
				SliderBarFrameConstraint.MaxSize = Vector2.new(224, 14)
				SliderBarFrameConstraint.Parent = SliderBarFrame

				local TextLabel_6 = Instance.new("TextLabel")
				TextLabel_6.Name = "TextLabel"
				TextLabel_6.AnchorPoint = Vector2.new(0, 0.5)
				TextLabel_6.Size = UDim2.new(0, 14, 0, 14)
				TextLabel_6.BorderColor3 = Color3.new(0, 0, 0)
				TextLabel_6.BorderSizePixel = 0
				TextLabel_6.BackgroundTransparency = 1
				TextLabel_6.Position = UDim2.new(0, 0, 0.5, 0)
				TextLabel_6.BackgroundColor3 = Color3.new(1, 1, 1)
				TextLabel_6.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
				TextLabel_6.TextColor3 = Color3.new(0.65, 0.65, 0.65)
				TextLabel_6.Text = "-"
				TextLabel_6.TextXAlignment = Enum.TextXAlignment.Center
				TextLabel_6.Parent = SliderBarFrame

				local UITextSizeConstraint_9 = Instance.new("UITextSizeConstraint")
				UITextSizeConstraint_9.Name = "UITextSizeConstraint"
				UITextSizeConstraint_9.MinTextSize = 14
				UITextSizeConstraint_9.Parent = TextLabel_6

				local TextLabel_5 = Instance.new("TextLabel")
				TextLabel_5.Name = "TextLabel"
				TextLabel_5.AnchorPoint = Vector2.new(1, 0.5)
				TextLabel_5.Size = UDim2.new(0, 14, 0, 14)
				TextLabel_5.BorderColor3 = Color3.new(0, 0, 0)
				TextLabel_5.BorderSizePixel = 0
				TextLabel_5.BackgroundTransparency = 1
				TextLabel_5.Position = UDim2.new(1, 0, 0.5, 0)
				TextLabel_5.BackgroundColor3 = Color3.new(1, 1, 1)
				TextLabel_5.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
				TextLabel_5.TextColor3 = Color3.new(0.65, 0.65, 0.65)
				TextLabel_5.Text = "+"
				TextLabel_5.TextXAlignment = Enum.TextXAlignment.Center
				TextLabel_5.Parent = SliderBarFrame

				local UITextSizeConstraint_8 = Instance.new("UITextSizeConstraint")
				UITextSizeConstraint_8.Name = "UITextSizeConstraint"
				UITextSizeConstraint_8.MinTextSize = 14
				UITextSizeConstraint_8.Parent = TextLabel_5

				local Frame_6 = Instance.new("Frame")
				Frame_6.Name = "Frame"
				Frame_6.AnchorPoint = Vector2.new(0.5, 0.5)
				Frame_6.Size = UDim2.new(1, -38, 0, 5)
				Frame_6.Position = UDim2.new(0.5, 0, 0.5, 0)
				Frame_6.BorderColor3 = Color3.new(0, 0, 0)
				Frame_6.BorderSizePixel = 0
				Frame_6.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				Frame_6.Parent = SliderBarFrame

				local UIStroke_7 = Instance.new("UIStroke")
				UIStroke_7.Name = "UIStroke"
				UIStroke_7.Color = Color3.new(0.16, 0.16, 0.16)
				UIStroke_7.Thickness = 1.4
				UIStroke_7.LineJoinMode = Enum.LineJoinMode.Miter
				UIStroke_7.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				UIStroke_7.Parent = Frame_6

				local FillFrame = Instance.new("Frame")
				FillFrame.Name = "FillFrame"
				FillFrame.Size = UDim2.new(0, 0, 1, 0)
				FillFrame.Position = UDim2.new(0, 0, 0, 0)
				FillFrame.BackgroundColor3 = accent_color
				FillFrame.BorderSizePixel = 0
				FillFrame.Parent = Frame_6

				local TextButton = Instance.new("TextButton")
				TextButton.Name = "TextButton"
				TextButton.Size = UDim2.new(0, 4, 0, 5)
				TextButton.BorderColor3 = Color3.new(0, 0, 0)
				TextButton.BorderSizePixel = 0
				TextButton.BackgroundTransparency = 1
				TextButton.Text = ""
				TextButton.Parent = Frame_6

				local ValueLabel = Instance.new("TextLabel")
				ValueLabel.Name = "ValueLabel"
				ValueLabel.AnchorPoint = Vector2.new(0.5, 0)
				ValueLabel.Size = UDim2.new(0, 70, 0, 14)
				ValueLabel.Position = UDim2.new(0, 0, 1, 2)
				ValueLabel.BackgroundTransparency = 1
				ValueLabel.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
				ValueLabel.TextColor3 = Color3.new(0.65, 0.65, 0.65)
				ValueLabel.Text = tostring(default) .. Suffix
				ValueLabel.TextXAlignment = Enum.TextXAlignment.Center
				ValueLabel.Parent = Frame_6

				local ValueLabelUITextSizeConstraint_8 = Instance.new("UITextSizeConstraint")
				ValueLabelUITextSizeConstraint_8.Name = "UITextSizeConstraint"
				ValueLabelUITextSizeConstraint_8.MinTextSize = 14
				ValueLabelUITextSizeConstraint_8.Parent = ValueLabel

				local value = math.clamp(default, Min, Max)
				local dragging = false

				local function isPrimaryInput(input)
					return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
				end

				local function isDragInput(input)
					return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
				end

				local function round(num)
					return math.floor(num / Rounding + 0.5) * Rounding
				end

				local function setValue(val)
					val = tonumber(val)
					if not val then
						return
					end
					value = math.clamp(round(val), Min, Max)
					local percent = Max == Min and 0 or (value - Min) / (Max - Min)
					TweenService:Create(TextButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Position = UDim2.new(percent, -2, 0, 0)
					}):Play()
					TweenService:Create(FillFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(percent, 0, 1, 0)
					}):Play()
					TweenService:Create(ValueLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Position = UDim2.new(percent, 0, 1, 2)
					}):Play()
					ValueLabel.Text = tostring(value) .. Suffix
					pcall(callback, value)
				end

				local function inputToValue(input)
					local pos = (input.Position.X - Frame_6.AbsolutePosition.X) / Frame_6.AbsoluteSize.X
					pos = math.clamp(pos, 0, 1)
					local val = Min + (Max - Min) * pos
					setValue(val)
				end

				Frame_6.InputBegan:Connect(function(input)
					if isPrimaryInput(input) then
						dragging = true
						inputToValue(input)
					end
				end)

				TextButton.InputBegan:Connect(function(input)
					if isPrimaryInput(input) then
						dragging = true
						inputToValue(input)
					end
				end)

				UIS.InputChanged:Connect(function(input)
					if dragging and isDragInput(input) then
						inputToValue(input)
					end
				end)

				UIS.InputEnded:Connect(function(input)
					if isPrimaryInput(input) then
						dragging = false
					end
				end)

				TextLabel_5.InputBegan:Connect(function(input)
					if isPrimaryInput(input) then
						setValue(value + Rounding)
					end
				end)

				TextLabel_6.InputBegan:Connect(function(input)
					if isPrimaryInput(input) then
						setValue(value - Rounding)
					end
				end)

				setValue(default)

				local sliderObj
				sliderObj = {
					Set = function(selfOrVal, val)
						local v = extractArg(selfOrVal, val, sliderObj)
						setValue(v)
					end,
					SetValue = function(selfOrVal, val)
						local v = extractArg(selfOrVal, val, sliderObj)
						setValue(v)
					end,
					Get = function()
						return value
					end,
					GetValue = function()
						return value
					end,
					GetVisiblity = function()
						return Slider.Visible
					end,
					GetVisibility = function()
						return Slider.Visible
					end,
					SetVisiblity = function(selfOrVal, val)
						local bool = extractArg(selfOrVal, val, sliderObj)
						if type(bool) == "boolean" then
							Slider.Visible = bool
							queueSectionScrollUpdate()
						end
					end,
					SetVisibility = function(selfOrVal, val)
						local bool = extractArg(selfOrVal, val, sliderObj)
						if type(bool) == "boolean" then
							Slider.Visible = bool
							queueSectionScrollUpdate()
						end
					end,
					GetDisplayOrder = function()
						return Slider.LayoutOrder
					end,
					GetLayoutOrder = function()
						return Slider.LayoutOrder
					end,
					GetOrder = function()
						return Slider.LayoutOrder
					end,
					SetDisplayOrder = function(selfOrVal, val)
						local order = extractArg(selfOrVal, val, sliderObj)
						local num = tonumber(order)
						if num then
							Slider.LayoutOrder = math.floor(num)
							queueSectionScrollUpdate()
						end
					end,
					SetLayoutOrder = function(selfOrVal, val)
						local order = extractArg(selfOrVal, val, sliderObj)
						local num = tonumber(order)
						if num then
							Slider.LayoutOrder = math.floor(num)
							queueSectionScrollUpdate()
						end
					end,
					SetOrder = function(selfOrVal, val)
						local order = extractArg(selfOrVal, val, sliderObj)
						local num = tonumber(order)
						if num then
							Slider.LayoutOrder = math.floor(num)
							queueSectionScrollUpdate()
						end
					end
				}

				registerSectItem(name, sliderObj, Slider, initialOrder)
				applyOrderMethods(sliderObj, Slider)
				sm:Register(name, sliderObj, "Slider")

				queueSectionScrollUpdate()
				return sliderObj
			end

			function sect:CreateDropdown(name, options)
				options = options or {}
				local initialOrder = extractOrderFromOptions(options)

				local title = options.Title or options.title or ""
				local Values = options.Values or {""}
				local Multi = options.Multi or false
				local default = options.Default or (Multi and {} or nil)
				local callback = options.callback or function() end

				local TweenService = game:GetService("TweenService")

				local hasTitle = title ~= "" and title ~= nil

				local Dropdown = Instance.new("Frame")
				Dropdown.Name = "Dropdown"
				Dropdown.Size = UDim2.new(1, 0, 0, hasTitle and 45 or 28)
				Dropdown.BorderSizePixel = 0
				Dropdown.BackgroundTransparency = 1
				Dropdown.Position = UDim2.new(0, 0, 0.08, 0)
				Dropdown.Parent = ScrollingFrame

				if hasTitle then
					local TextLabel_7 = Instance.new("TextLabel")
					TextLabel_7.AnchorPoint = Vector2.new(0.5, 0)
					TextLabel_7.Size = UDim2.new(0.82, 0, 0, 16)
					TextLabel_7.BackgroundTransparency = 1
					TextLabel_7.Position = UDim2.new(0.5, 0, 0, 1)
					TextLabel_7.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium)
					TextLabel_7.TextColor3 = Color3.new(0.65, 0.65, 0.65)
					TextLabel_7.Text = title
					TextLabel_7.TextXAlignment = Enum.TextXAlignment.Left
					TextLabel_7.Parent = Dropdown

					local DropdownTitleConstraint = Instance.new("UISizeConstraint")
					DropdownTitleConstraint.MaxSize = Vector2.new(224, 16)
					DropdownTitleConstraint.Parent = TextLabel_7

					local UITextSizeConstraint_10 = Instance.new("UITextSizeConstraint")
					UITextSizeConstraint_10.MinTextSize = 14
					UITextSizeConstraint_10.Parent = TextLabel_7
				end

				local DropdownFrame = Instance.new("Frame")
				DropdownFrame.AnchorPoint = Vector2.new(0.5, 0)
				DropdownFrame.Size = UDim2.new(0.82, 0, 0, 21)
				DropdownFrame.Position = UDim2.new(0.5, 0, 0, hasTitle and 19 or 0)
				DropdownFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				DropdownFrame.BorderSizePixel = 0
				DropdownFrame.Parent = Dropdown

				local DropdownFrameConstraint = Instance.new("UISizeConstraint")
				DropdownFrameConstraint.MaxSize = Vector2.new(224, 21)
				DropdownFrameConstraint.Parent = DropdownFrame

				local UIStroke_8 = Instance.new("UIStroke")
				UIStroke_8.Color = Color3.new(0.16, 0.16, 0.16)
				UIStroke_8.Thickness = 1.4
				UIStroke_8.Parent = DropdownFrame

				local TextLabel_8 = Instance.new("TextLabel")
				TextLabel_8.Size = UDim2.new(0.78, 0, 0.55, 0)
				TextLabel_8.BackgroundTransparency = 1
				TextLabel_8.Position = UDim2.new(0.07, 0, 0.22, 0)
				TextLabel_8.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium)
				TextLabel_8.TextColor3 = Color3.new(0.65, 0.65, 0.65)
				TextLabel_8.Text = "None"
				TextLabel_8.TextXAlignment = Enum.TextXAlignment.Left
				TextLabel_8.Parent = DropdownFrame

				local UITextSizeConstraint_11 = Instance.new("UITextSizeConstraint")
				UITextSizeConstraint_11.MinTextSize = 14
				UITextSizeConstraint_11.Parent = TextLabel_8

				local ImageLabel = Instance.new("ImageLabel")
				ImageLabel.Size = UDim2.new(0, 12, 0, 12)
				ImageLabel.Position = UDim2.new(0.91, 0, 0.19, 0)
				ImageLabel.BackgroundTransparency = 1
				ImageLabel.Image = "rbxassetid://138201579718575"
				ImageLabel.Rotation = 0
				ImageLabel.Parent = DropdownFrame

				local Button = Instance.new("TextButton")
				Button.Size = UDim2.new(1, 0, 1, 0)
				Button.BackgroundTransparency = 1
				Button.Text = ""
				Button.Parent = DropdownFrame

				local ListFrame = Instance.new("Frame")
				ListFrame.AnchorPoint = Vector2.new(0.5, 0)
				ListFrame.Size = UDim2.new(0.82, 0, 0, 0)
				ListFrame.Position = UDim2.new(0.5, 0, 0, hasTitle and 40 or 21)
				ListFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				ListFrame.BorderSizePixel = 0
				ListFrame.ClipsDescendants = true
				ListFrame.Parent = Dropdown
				ListFrame.ZIndex = 3

				local ListFrameConstraint = Instance.new("UISizeConstraint")
				ListFrameConstraint.MaxSize = Vector2.new(224, 9999)
				ListFrameConstraint.Parent = ListFrame

				local UIStroke_List = Instance.new("UIStroke")
				UIStroke_List.Color = Color3.new(0.16, 0.16, 0.16)
				UIStroke_List.Thickness = 1.4
				UIStroke_List.Parent = ListFrame

				local UIListLayout = Instance.new("UIListLayout")
				UIListLayout.Parent = ListFrame
				UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

				local opened = false
				local selected
				if Multi then
					selected = {}
					if type(default) == "table" then
						for k, v in pairs(default) do
							if type(k) == "number" and type(v) == "string" then
								selected[v] = true
							elseif type(v) == "boolean" then
								selected[tostring(k)] = v
							end
						end
					end
				else
					selected = (type(default) == "table" and #default > 0) and default[1] or default
				end

				local optionButtons = {}

				local function updateText()
					if Multi then
						local t = {}
						for v,_ in pairs(selected) do
							if selected[v] then
								table.insert(t, v)
							end
						end
						TextLabel_8.Text = #t > 0 and table.concat(t, ", ") or "None"
						for i, btn in pairs(optionButtons) do
							btn.TextColor3 = selected[btn.Name] and Color3.fromRGB(255,255,255) or Color3.new(0.65,0.65,0.65)
						end
						pcall(callback, selected)
					else
						TextLabel_8.Text = selected ~= nil and tostring(selected) or "None"
						for i, btn in pairs(optionButtons) do
							btn.TextColor3 = (btn.Name == selected) and Color3.fromRGB(255,255,255) or Color3.new(0.65,0.65,0.65)
						end
						pcall(callback, selected)
					end
				end

				local function toggle()
					opened = not opened
					local size = opened and (#Values * 20) or 0
					local baseHeight = hasTitle and 45 or 28
					TweenService:Create(ListFrame, TweenInfo.new(0.15), {
						Size = UDim2.new(0.82, 0, 0, size)
					}):Play()
					TweenService:Create(Dropdown, TweenInfo.new(0.15), {
						Size = UDim2.new(1, 0, 0, baseHeight + size)
					}):Play()
					TweenService:Create(ImageLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Rotation = opened and 180 or 0
					}):Play()
					queueSectionScrollUpdate()
					task.delay(0.16, queueSectionScrollUpdate)
				end

				Button.MouseButton1Click:Connect(toggle)

				for i,v in ipairs(Values) do
					local Option = Instance.new("TextButton")
					Option.Name = v
					Option.Size = UDim2.new(1, 0, 0, 20)
					Option.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
					Option.BorderSizePixel = 0
					Option.Text = v
					Option.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium)
					Option.TextColor3 = Color3.new(0.65,0.65,0.65)
					Option.TextXAlignment = Enum.TextXAlignment.Left
					Option.ZIndex = 5
					Option.Parent = ListFrame

					local Option_UITextSizeConstraint = Instance.new("UITextSizeConstraint")
					Option_UITextSizeConstraint.MinTextSize = 14
					Option_UITextSizeConstraint.Parent = Option

					optionButtons[v] = Option

					Option.MouseButton1Click:Connect(function()
						if Multi then
							selected[v] = not selected[v]
						else
							selected = v
							toggle()
						end
						updateText()
					end)
				end

				updateText()
				queueSectionScrollUpdate()

				local dropdownObj
				dropdownObj = {
					Get = function()
						return selected
					end,
					GetValue = function()
						return selected
					end,
					Set = function(selfOrVal, val)
						local v = extractArg(selfOrVal, val, dropdownObj)
						if Multi then
							if type(v) == "table" then
								selected = {}
								for key, enabled in pairs(v) do
									if type(key) == "number" and type(enabled) == "string" then
										selected[enabled] = true
									elseif type(enabled) == "boolean" then
										selected[tostring(key)] = enabled
									end
								end
							end
						else
							if type(v) == "table" then
								if #v > 0 then
									selected = tostring(v[1])
								end
							elseif v ~= nil then
								selected = tostring(v)
							end
						end
						updateText()
					end,
					SetValue = function(selfOrVal, val)
						dropdownObj.Set(selfOrVal, val)
					end,
					SetValues = function(selfOrVal, val)
						local newValues = extractArg(selfOrVal, val, dropdownObj)
						newValues = type(newValues) == "table" and newValues or {}
						Values = newValues
						for _, btn in pairs(optionButtons) do
							btn:Destroy()
						end
						optionButtons = {}
						if Multi then
							selected = {}
						else
							selected = nil
						end
						for _, opt in ipairs(newValues) do
							local Option = Instance.new("TextButton")
							Option.Name = opt
							Option.Size = UDim2.new(1, 0, 0, 20)
							Option.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
							Option.BorderSizePixel = 0
							Option.Text = opt
							Option.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium)
							Option.TextColor3 = Color3.new(0.65,0.65,0.65)
							Option.TextXAlignment = Enum.TextXAlignment.Left
							Option.ZIndex = 5
							Option.Parent = ListFrame

							local Option_UITextSizeConstraint = Instance.new("UITextSizeConstraint")
							Option_UITextSizeConstraint.MinTextSize = 14
							Option_UITextSizeConstraint.Parent = Option

							optionButtons[opt] = Option

							Option.MouseButton1Click:Connect(function()
								if Multi then
									selected[opt] = not selected[opt]
								else
									selected = opt
									toggle()
								end
								updateText()
							end)
						end
						updateText()
						queueSectionScrollUpdate()
					end,
					GetVisiblity = function()
						return Dropdown.Visible
					end,
					GetVisibility = function()
						return Dropdown.Visible
					end,
					SetVisiblity = function(selfOrVal, val)
						local bool = extractArg(selfOrVal, val, dropdownObj)
						if type(bool) == "boolean" then
							Dropdown.Visible = bool
							queueSectionScrollUpdate()
						end
					end,
					SetVisibility = function(selfOrVal, val)
						local bool = extractArg(selfOrVal, val, dropdownObj)
						if type(bool) == "boolean" then
							Dropdown.Visible = bool
							queueSectionScrollUpdate()
						end
					end,
					GetDisplayOrder = function()
						return Dropdown.LayoutOrder
					end,
					GetLayoutOrder = function()
						return Dropdown.LayoutOrder
					end,
					GetOrder = function()
						return Dropdown.LayoutOrder
					end,
					SetDisplayOrder = function(selfOrVal, val)
						local order = extractArg(selfOrVal, val, dropdownObj)
						local num = tonumber(order)
						if num then
							Dropdown.LayoutOrder = math.floor(num)
							queueSectionScrollUpdate()
						end
					end,
					SetLayoutOrder = function(selfOrVal, val)
						local order = extractArg(selfOrVal, val, dropdownObj)
						local num = tonumber(order)
						if num then
							Dropdown.LayoutOrder = math.floor(num)
							queueSectionScrollUpdate()
						end
					end,
					SetOrder = function(selfOrVal, val)
						local order = extractArg(selfOrVal, val, dropdownObj)
						local num = tonumber(order)
						if num then
							Dropdown.LayoutOrder = math.floor(num)
							queueSectionScrollUpdate()
						end
					end
				}

				registerSectItem(name, dropdownObj, Dropdown, initialOrder)
				applyOrderMethods(dropdownObj, Dropdown)
				sm:Register(name, dropdownObj, "Dropdown")

				return dropdownObj
			end

			function sect:CreateListbox(name, options)
				options = options or {}
				local initialOrder = extractOrderFromOptions(options)

				local title = options.Title or options.title or ""
				local Values = options.Values or {""}
				local Multi = options.Multi or false
				local default = options.Default or (Multi and {} or nil)
				local MaxVisible = options.MaxVisible or 4
				local callback = options.callback or function() end

				local itemHeight = 20
				local listHeight = math.min(#Values, MaxVisible) * itemHeight
				local hasTitle = title ~= "" and title ~= nil

				local Listbox = Instance.new("Frame")
				Listbox.Name = "Listbox"
				Listbox.Size = UDim2.new(1, 0, 0, hasTitle and (25 + listHeight) or (listHeight + 8))
				Listbox.BorderSizePixel = 0
				Listbox.BackgroundTransparency = 1
				Listbox.Position = UDim2.new(0, 0, 0.08, 0)
				Listbox.Parent = ScrollingFrame

				if hasTitle then
					local TitleLabel = Instance.new("TextLabel")
					TitleLabel.AnchorPoint = Vector2.new(0.5, 0)
					TitleLabel.Size = UDim2.new(0.82, 0, 0, 16)
					TitleLabel.BackgroundTransparency = 1
					TitleLabel.Position = UDim2.new(0.5, 0, 0, 1)
					TitleLabel.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium)
					TitleLabel.TextColor3 = Color3.new(0.65, 0.65, 0.65)
					TitleLabel.Text = title
					TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
					TitleLabel.Parent = Listbox

					local TitleSizeConstraint = Instance.new("UISizeConstraint")
					TitleSizeConstraint.MaxSize = Vector2.new(224, 16)
					TitleSizeConstraint.Parent = TitleLabel

					local TitleTextConstraint = Instance.new("UITextSizeConstraint")
					TitleTextConstraint.MinTextSize = 14
					TitleTextConstraint.Parent = TitleLabel
				end

				local ListContainer = Instance.new("ScrollingFrame")
				ListContainer.Name = "ListContainer"
				ListContainer.Size = UDim2.new(0.82, 0, 0, listHeight)
				ListContainer.AnchorPoint = Vector2.new(0.5, 0)
				ListContainer.Position = UDim2.new(0.5, 0, 0, hasTitle and 19 or 0)
				ListContainer.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				ListContainer.BorderSizePixel = 0
				ListContainer.CanvasSize = UDim2.new(0, 0, 0, #Values * itemHeight)
				ListContainer.ScrollBarImageColor3 = accent_color
				ListContainer.ScrollBarImageTransparency = 0
				ListContainer.ScrollBarThickness = (#Values > MaxVisible) and 4 or 0
				ListContainer.ScrollingDirection = Enum.ScrollingDirection.Y
				ListContainer.AutomaticCanvasSize = Enum.AutomaticSize.None
				ListContainer.Parent = Listbox

				local ListContainerSizeConstraint = Instance.new("UISizeConstraint")
				ListContainerSizeConstraint.MaxSize = Vector2.new(224, 9999)
				ListContainerSizeConstraint.Parent = ListContainer

				local ListStroke = Instance.new("UIStroke")
				ListStroke.Color = Color3.new(0.16, 0.16, 0.16)
				ListStroke.Thickness = 1.4
				ListStroke.LineJoinMode = Enum.LineJoinMode.Miter
				ListStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				ListStroke.Parent = ListContainer

				local ListLayout = Instance.new("UIListLayout")
				ListLayout.Parent = ListContainer
				ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

				local selected
				if Multi then
					selected = {}
					if type(default) == "table" then
						for k, v in pairs(default) do
							if type(k) == "number" and type(v) == "string" then
								selected[v] = true
							elseif type(v) == "boolean" then
								selected[tostring(k)] = v
							end
						end
					end
				else
					selected = (type(default) == "table" and #default > 0) and default[1] or default
				end

				local optionButtons = {}

				local function updateHighlights()
					for _, btn in pairs(optionButtons) do
						if Multi then
							btn.TextColor3 = selected[btn.Name] and Color3.fromRGB(255, 255, 255) or Color3.new(0.65, 0.65, 0.65)
						else
							btn.TextColor3 = (btn.Name == selected) and Color3.fromRGB(255, 255, 255) or Color3.new(0.65, 0.65, 0.65)
						end
					end
				end

				for i, v in ipairs(Values) do
					local Option = Instance.new("TextButton")
					Option.Name = v
					Option.Size = UDim2.new(1, 0, 0, itemHeight)
					Option.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
					Option.BorderSizePixel = 0
					Option.Text = "  " .. v
					Option.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium)
					Option.TextColor3 = Color3.new(0.65, 0.65, 0.65)
					Option.TextXAlignment = Enum.TextXAlignment.Left
					Option.Parent = ListContainer

					local OptionTextConstraint = Instance.new("UITextSizeConstraint")
					OptionTextConstraint.MinTextSize = 14
					OptionTextConstraint.Parent = Option

					optionButtons[v] = Option

					Option.MouseButton1Click:Connect(function()
						if Multi then
							selected[v] = not selected[v]
						else
							selected = v
						end
						updateHighlights()
						pcall(callback, selected)
					end)
				end

				updateHighlights()
				queueSectionScrollUpdate()

				local listboxObj
				listboxObj = {
					Get = function()
						return selected
					end,
					GetValue = function()
						return selected
					end,
					Set = function(selfOrVal, val)
						local v = extractArg(selfOrVal, val, listboxObj)
						if Multi then
							if type(v) == "table" then
								selected = {}
								for key, enabled in pairs(v) do
									if type(key) == "number" and type(enabled) == "string" then
										selected[enabled] = true
									elseif type(enabled) == "boolean" then
										selected[tostring(key)] = enabled
									end
								end
							end
						else
							if type(v) == "table" then
								if #v > 0 then
									selected = tostring(v[1])
								end
							elseif v ~= nil then
								selected = tostring(v)
							end
						end
						updateHighlights()
						pcall(callback, selected)
					end,
					SetValue = function(selfOrVal, val)
						listboxObj.Set(selfOrVal, val)
					end,
					SetValues = function(selfOrVal, val)
						local newValues = extractArg(selfOrVal, val, listboxObj)
						newValues = type(newValues) == "table" and newValues or {}
						Values = newValues
						for _, btn in pairs(optionButtons) do
							btn:Destroy()
						end
						optionButtons = {}
						if Multi then
							selected = {}
						else
							selected = nil
						end
						for i, v in ipairs(newValues) do
							local Option = Instance.new("TextButton")
							Option.Name = v
							Option.Size = UDim2.new(1, 0, 0, itemHeight)
							Option.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
							Option.BorderSizePixel = 0
							Option.Text = "  " .. v
							Option.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium)
							Option.TextColor3 = Color3.new(0.65, 0.65, 0.65)
							Option.TextXAlignment = Enum.TextXAlignment.Left
							Option.Parent = ListContainer

							local OptionTextConstraint = Instance.new("UITextSizeConstraint")
							OptionTextConstraint.MinTextSize = 14
							OptionTextConstraint.Parent = Option

							optionButtons[v] = Option

							Option.MouseButton1Click:Connect(function()
								if Multi then
									selected[v] = not selected[v]
								else
									selected = v
								end
								updateHighlights()
								pcall(callback, selected)
							end)
						end
						local newListHeight = math.min(#newValues, MaxVisible) * itemHeight
						ListContainer.Size = UDim2.new(0.82, 0, 0, newListHeight)
						ListContainer.CanvasSize = UDim2.new(0, 0, 0, #newValues * itemHeight)
						ListContainer.ScrollBarThickness = (#newValues > MaxVisible) and 4 or 0
						Listbox.Size = UDim2.new(1, 0, 0, hasTitle and (25 + newListHeight) or (newListHeight + 8))
						updateHighlights()
						queueSectionScrollUpdate()
					end,
					GetVisiblity = function()
						return Listbox.Visible
					end,
					GetVisibility = function()
						return Listbox.Visible
					end,
					SetVisiblity = function(selfOrVal, val)
						local bool = extractArg(selfOrVal, val, listboxObj)
						if type(bool) == "boolean" then
							Listbox.Visible = bool
							queueSectionScrollUpdate()
						end
					end,
					SetVisibility = function(selfOrVal, val)
						local bool = extractArg(selfOrVal, val, listboxObj)
						if type(bool) == "boolean" then
							Listbox.Visible = bool
							queueSectionScrollUpdate()
						end
					end,
					GetDisplayOrder = function()
						return Listbox.LayoutOrder
					end,
					GetLayoutOrder = function()
						return Listbox.LayoutOrder
					end,
					GetOrder = function()
						return Listbox.LayoutOrder
					end,
					SetDisplayOrder = function(selfOrVal, val)
						local order = extractArg(selfOrVal, val, listboxObj)
						local num = tonumber(order)
						if num then
							Listbox.LayoutOrder = math.floor(num)
							queueSectionScrollUpdate()
						end
					end,
					SetLayoutOrder = function(selfOrVal, val)
						local order = extractArg(selfOrVal, val, listboxObj)
						local num = tonumber(order)
						if num then
							Listbox.LayoutOrder = math.floor(num)
							queueSectionScrollUpdate()
						end
					end,
					SetOrder = function(selfOrVal, val)
						local order = extractArg(selfOrVal, val, listboxObj)
						local num = tonumber(order)
						if num then
							Listbox.LayoutOrder = math.floor(num)
							queueSectionScrollUpdate()
						end
					end
				}

				registerSectItem(name, listboxObj, Listbox, initialOrder)
				applyOrderMethods(listboxObj, Listbox)
				sm:Register(name, listboxObj, "Listbox")

				return listboxObj
			end

			function sect:CreateTextbox(name, options)
				options = options or {}
				local initialOrder = extractOrderFromOptions(options)

				local title = options.Title or options.title or ""
				local default = options.Default or ""
				local placeholder = options.Placeholder or ""
				local callback = options.callback or function() end

				local hasTitle = title ~= "" and title ~= nil

				local Textbox = Instance.new("Frame")
				Textbox.Name = "Textbox"
				Textbox.Size = UDim2.new(1, 0, 0, hasTitle and 45 or 28)
				Textbox.BorderSizePixel = 0
				Textbox.BackgroundTransparency = 1
				Textbox.Position = UDim2.new(0, 0, 0.08, 0)
				Textbox.Parent = ScrollingFrame

				if hasTitle then
					local TitleLabel = Instance.new("TextLabel")
					TitleLabel.AnchorPoint = Vector2.new(0.5, 0)
					TitleLabel.Size = UDim2.new(0.82, 0, 0, 16)
					TitleLabel.BackgroundTransparency = 1
					TitleLabel.Position = UDim2.new(0.5, 0, 0, 1)
					TitleLabel.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium)
					TitleLabel.TextColor3 = Color3.new(0.65, 0.65, 0.65)
					TitleLabel.Text = title
					TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
					TitleLabel.Parent = Textbox

					local TitleSizeConstraint = Instance.new("UISizeConstraint")
					TitleSizeConstraint.MaxSize = Vector2.new(224, 16)
					TitleSizeConstraint.Parent = TitleLabel

					local TitleTextConstraint = Instance.new("UITextSizeConstraint")
					TitleTextConstraint.MinTextSize = 14
					TitleTextConstraint.Parent = TitleLabel
				end

				local InputFrame = Instance.new("Frame")
				InputFrame.Size = UDim2.new(0.82, 0, 0, 21)
				InputFrame.AnchorPoint = Vector2.new(0.5, 0)
				InputFrame.Position = UDim2.new(0.5, 0, 0, hasTitle and 19 or 0)
				InputFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				InputFrame.BorderSizePixel = 0
				InputFrame.Parent = Textbox

				local InputFrameConstraint = Instance.new("UISizeConstraint")
				InputFrameConstraint.MaxSize = Vector2.new(224, 21)
				InputFrameConstraint.Parent = InputFrame

				local InputStroke = Instance.new("UIStroke")
				InputStroke.Color = Color3.fromRGB(41, 42, 42)
				InputStroke.Thickness = 1.4
				InputStroke.LineJoinMode = Enum.LineJoinMode.Miter
				InputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				InputStroke.Parent = InputFrame

				local Input = Instance.new("TextBox")
				Input.Name = "Input"
				Input.Size = UDim2.new(1, -14, 1, 0)
				Input.Position = UDim2.new(0, 7, 0, 0)
				Input.BackgroundTransparency = 1
				Input.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium)
				Input.TextColor3 = Color3.new(0.65, 0.65, 0.65)
				Input.PlaceholderText = placeholder
				Input.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
				Input.Text = default
				Input.TextXAlignment = Enum.TextXAlignment.Left
				Input.ClearTextOnFocus = false
				Input.Parent = InputFrame

				local InputTextConstraint = Instance.new("UITextSizeConstraint")
				InputTextConstraint.MinTextSize = 14
				InputTextConstraint.Parent = Input

				Input.FocusLost:Connect(function(enterPressed)
					pcall(callback, Input.Text, enterPressed)
				end)

				queueSectionScrollUpdate()

				local textboxObj
				textboxObj = {
					Get = function()
						return Input.Text
					end,
					GetValue = function()
						return Input.Text
					end,
					Set = function(selfOrVal, val)
						local v = extractArg(selfOrVal, val, textboxObj)
						Input.Text = tostring(v or "")
						pcall(callback, Input.Text, false)
					end,
					SetValue = function(selfOrVal, val)
						textboxObj.Set(selfOrVal, val)
					end,
					GetVisiblity = function()
						return Textbox.Visible
					end,
					GetVisibility = function()
						return Textbox.Visible
					end,
					SetVisiblity = function(selfOrVal, val)
						local bool = extractArg(selfOrVal, val, textboxObj)
						if type(bool) == "boolean" then
							Textbox.Visible = bool
							queueSectionScrollUpdate()
						end
					end,
					SetVisibility = function(selfOrVal, val)
						local bool = extractArg(selfOrVal, val, textboxObj)
						if type(bool) == "boolean" then
							Textbox.Visible = bool
							queueSectionScrollUpdate()
						end
					end,
					GetDisplayOrder = function()
						return Textbox.LayoutOrder
					end,
					GetLayoutOrder = function()
						return Textbox.LayoutOrder
					end,
					GetOrder = function()
						return Textbox.LayoutOrder
					end,
					SetDisplayOrder = function(selfOrVal, val)
						local order = extractArg(selfOrVal, val, textboxObj)
						local num = tonumber(order)
						if num then
							Textbox.LayoutOrder = math.floor(num)
							queueSectionScrollUpdate()
						end
					end,
					SetLayoutOrder = function(selfOrVal, val)
						local order = extractArg(selfOrVal, val, textboxObj)
						local num = tonumber(order)
						if num then
							Textbox.LayoutOrder = math.floor(num)
							queueSectionScrollUpdate()
						end
					end,
					SetOrder = function(selfOrVal, val)
						local order = extractArg(selfOrVal, val, textboxObj)
						local num = tonumber(order)
						if num then
							Textbox.LayoutOrder = math.floor(num)
							queueSectionScrollUpdate()
						end
					end
				}

				registerSectItem(name, textboxObj, Textbox, initialOrder)
				applyOrderMethods(textboxObj, Textbox)
				sm:Register(name, textboxObj, "Textbox")

				return textboxObj
			end
			return sect
		end

		function tab:CreateSection(sectionName, Parent)
			if #tab.Subtabs > 0 then
				local targetSub = tab.ActiveSubtab or tab.Subtabs[1]
				return targetSub:CreateSection(sectionName, Parent)
			end
			return createSectionInternal(Left, Right, TabFrame, sectionName, Parent)
		end

function tab:CreateSubtab(subtabname)
	if tab.SubtabBar == nil then
		Left.Visible = false
		Right.Visible = false

		local SubtabBar = Instance.new("Frame")
		SubtabBar.Name = "SubtabBar"
		SubtabBar.Size = UDim2.new(1, 0, 0, 26)
		SubtabBar.Position = UDim2.new(0, 0, 0, 0)
		SubtabBar.BackgroundColor3 = Color3.new(0.08, 0.08, 0.08)
		SubtabBar.BorderSizePixel = 0
		SubtabBar.ZIndex = 10
		SubtabBar.Parent = TabFrame

		local SubtabDivider = Instance.new("Frame")
		SubtabDivider.Name = "Divider"
		SubtabDivider.Size = UDim2.new(1, 0, 0, 1)
		SubtabDivider.Position = UDim2.new(0, 0, 1, -1)
		SubtabDivider.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		SubtabDivider.BorderSizePixel = 0
		SubtabDivider.Parent = SubtabBar

		local SubtabButtonsHolder = Instance.new("ScrollingFrame")
		SubtabButtonsHolder.Name = "SubtabButtonsHolder"
		SubtabButtonsHolder.Size = UDim2.new(1, -20, 1, 0)
		SubtabButtonsHolder.Position = UDim2.new(0, 10, 0, 0)
		SubtabButtonsHolder.BackgroundTransparency = 1
		SubtabButtonsHolder.BorderSizePixel = 0
		SubtabButtonsHolder.ScrollBarThickness = 0
		SubtabButtonsHolder.ScrollingDirection = Enum.ScrollingDirection.X
		SubtabButtonsHolder.AutomaticCanvasSize = Enum.AutomaticSize.X
		SubtabButtonsHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
		SubtabButtonsHolder.Parent = SubtabBar

		local SubtabLayout = Instance.new("UIListLayout")
		SubtabLayout.Name = "SubtabLayout"
		SubtabLayout.FillDirection = Enum.FillDirection.Horizontal
		SubtabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		SubtabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		SubtabLayout.SortOrder = Enum.SortOrder.LayoutOrder
		SubtabLayout.Padding = UDim.new(0, 0)
		SubtabLayout.Parent = SubtabButtonsHolder

		tab.SubtabBar = SubtabBar
		tab.SubtabButtonsHolder = SubtabButtonsHolder
	end

	local SubtabButton = Instance.new("TextButton")
	SubtabButton.Name = subtabname .. "_SubButton"
	SubtabButton.AutomaticSize = Enum.AutomaticSize.X
	SubtabButton.Size = UDim2.new(0, 0, 0, 26)
	SubtabButton.BackgroundTransparency = 1
	SubtabButton.BorderSizePixel = 0
	SubtabButton.Text = subtabname
	SubtabButton.FontFace = Font.new("rbxassetid://12187370747", Enum.FontWeight.Medium)
	SubtabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
	SubtabButton.LayoutOrder = #tab.Subtabs + 1
	SubtabButton.Parent = tab.SubtabButtonsHolder

	-- Modified padding logic for first subtab
	local SubUIPadding = Instance.new("UIPadding")
	if #tab.Subtabs == 0 then
		-- First subtab gets 0 left padding, 2 right padding
		SubUIPadding.PaddingLeft = UDim.new(0, 0)
		SubUIPadding.PaddingRight = UDim.new(0, 4)
	else
		-- All other subtabs get 5 padding on both sides
		SubUIPadding.PaddingLeft = UDim.new(0, 4)
		SubUIPadding.PaddingRight = UDim.new(0, 4)
	end
	SubUIPadding.Parent = SubtabButton

	local SubUITextSizeConstraint = Instance.new("UITextSizeConstraint")
	SubUITextSizeConstraint.MinTextSize = 14
	SubUITextSizeConstraint.Parent = SubtabButton

	local SubContent = Instance.new("Frame")
	SubContent.Name = subtabname .. "_Content"
	SubContent.Size = UDim2.new(1, 0, 1, -26)
	SubContent.Position = UDim2.new(0, 0, 0, 26)
	SubContent.BackgroundTransparency = 1
	SubContent.Visible = false
	SubContent.Parent = TabFrame

	local SubLeft, SubRight = createColumns(SubContent)

	local subtab = {
		Name = subtabname,
		Button = SubtabButton,
		Content = SubContent,
		Left = SubLeft,
		Right = SubRight
	}

	function subtab:CreateSection(sectionName, Parent)
		return createSectionInternal(SubLeft, SubRight, SubContent, sectionName, Parent)
	end

	function subtab:GetDisplayOrder()
		return SubtabButton.LayoutOrder
	end
	function subtab:SetDisplayOrder(order)
		local num = tonumber(order)
		if num then
			SubtabButton.LayoutOrder = math.floor(num)
		end
	end
	subtab.GetLayoutOrder = subtab.GetDisplayOrder
	subtab.SetLayoutOrder = subtab.SetDisplayOrder

	SubtabButton.MouseButton1Click:Connect(function()
		activateSubtab(subtab)
	end)

	SubtabButton.MouseEnter:Connect(function()
		if tab.ActiveSubtab ~= subtab then
			SubtabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end)

	SubtabButton.MouseLeave:Connect(function()
		if tab.ActiveSubtab ~= subtab then
			SubtabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end)

	table.insert(tab.Subtabs, subtab)

	if #tab.Subtabs == 1 then
		activateSubtab(subtab)
	end

	return subtab
end

		function tab:CreateSubTab(subtabname)
			return tab:CreateSubtab(subtabname)
		end

		function tab:GetDisplayOrder()
			return TabButton.LayoutOrder
		end
		function tab:SetDisplayOrder(order)
			local num = tonumber(order)
			if num then
				TabButton.LayoutOrder = math.floor(num)
			end
		end
		tab.GetLayoutOrder = tab.GetDisplayOrder
		tab.SetLayoutOrder = tab.SetDisplayOrder

		return tab
	end
	local Settings = window:CreateTab("Misc")
	window.Settings = Settings

	local configs = Settings:CreateSection("Configs", "Right")

	local selectedConfig = nil
	sm.Ignore.ConfigList = true
	sm.Ignore.ConfigName = true

	local configTextbox
	local configListbox

	configListbox = configs:CreateListbox("ConfigList", {
		Values = sm:GetConfigs(),
		Multi = false,
		MaxVisible = 5,
		callback = function(selected)
			selectedConfig = selected
			if type(selected) == "string" and selected ~= "" and configTextbox then
				configTextbox:Set(selected)
			end
		end
	})

	configTextbox = configs:CreateTextbox("ConfigName", {
		Placeholder = "Config name...",
		Default = ""
	})

	local function refreshList()
		local cfgs = sm:GetConfigs()
		configListbox:SetValues(cfgs)
	end

	configs:CreateButton("Create", function()
		local name = configTextbox and configTextbox:Get()
		if not name or name:gsub("%s+", "") == "" then return end
		sm:Save(name)
		refreshList()
		selectedConfig = name
		configListbox:Set(name)
	end)

	configs:CreateButton("Save", function()
		local name = (configTextbox and configTextbox:Get()) or selectedConfig
		if not name or name:gsub("%s+", "") == "" then
			name = selectedConfig
		end
		if name and name:gsub("%s+", "") ~= "" then
			sm:Save(name)
			refreshList()
			selectedConfig = name
			configListbox:Set(name)
		end
	end)

	configs:CreateButton("Load", function()
		local name = selectedConfig or (configTextbox and configTextbox:Get())
		if not name or name:gsub("%s+", "") == "" then
			name = (configTextbox and configTextbox:Get())
		end
		if name and name:gsub("%s+", "") ~= "" then
			sm:Load(name)
			selectedConfig = name
			configListbox:Set(name)
			if configTextbox then
				configTextbox:Set(name)
			end
		end
	end)

	configs:CreateButton("Delete", function()
		local name = selectedConfig or (configTextbox and configTextbox:Get())
		if name and name:gsub("%s+", "") ~= "" then
			sm:Delete(name)
			selectedConfig = nil
			refreshList()
			if configTextbox then
				configTextbox:Set("")
			end
		end
	end)

	configs:CreateButton("Refresh list", function()
		refreshList()
	end)
	return window
end

return Library
