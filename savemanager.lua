local httpService = (cloneref and cloneref(game:GetService("HttpService"))) or game:GetService("HttpService")
warn("save manager loaded!")

local SaveManager = {}
SaveManager.Folder = "plaguecheat"
SaveManager.Ignore = {}
SaveManager.Objects = {}
SaveManager.Pending = {}
SaveManager.Debug = false

local function isTable(value)
	if typeof then
		return typeof(value) == "table"
	end

	return type(value) == "table"
end

local function toBoolean(value)
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

	if type(value) == "number" then
		return value == 1
	end

	return nil
end

local function unwrapState(value)
	if not isTable(value) then
		return value
	end

	local current = value

	for _ = 1, 8 do
		if isTable(current) and current.State ~= nil then
			current = current.State
		else
			break
		end
	end

	if isTable(current) and current.Visible ~= nil and current.State == nil then
		return nil
	end

	return current
end

local function isControlObject(value)
	return isTable(value) and (
		value.Get ~= nil
		or value.GetValue ~= nil
		or value.Set ~= nil
		or value.SetValue ~= nil
		or value.Toggle ~= nil
		or value.GetVisiblity ~= nil
		or value.GetVisibility ~= nil
		or value.SetVisiblity ~= nil
		or value.SetVisibility ~= nil
		or value.GetDisplayOrder ~= nil
		or value.GetLayoutOrder ~= nil
		or value.SetDisplayOrder ~= nil
		or value.SetLayoutOrder ~= nil
		or value.SetBind ~= nil
		or value.SetValues ~= nil
	)
end

local function callMethod(obj, name, ...)
	if not obj then return end
	local fn = obj[name]
	if type(fn) ~= "function" and name == "Set" then
		fn = obj.SetValue
	elseif type(fn) ~= "function" and name == "Get" then
		fn = obj.GetValue
	elseif type(fn) ~= "function" and (name == "SetVisiblity" or name == "SetVisibility") then
		fn = obj.SetVisiblity or obj.SetVisibility
	elseif type(fn) ~= "function" and (name == "GetVisiblity" or name == "GetVisibility") then
		fn = obj.GetVisiblity or obj.GetVisibility
	elseif type(fn) ~= "function" and (name == "GetDisplayOrder" or name == "GetLayoutOrder") then
		fn = obj.GetDisplayOrder or obj.GetLayoutOrder
	elseif type(fn) ~= "function" and (name == "SetDisplayOrder" or name == "SetLayoutOrder") then
		fn = obj.SetDisplayOrder or obj.SetLayoutOrder
	end

	if type(fn) == "function" then
		return fn(obj, ...)
	end
end

local function toSavedSelection(value)
	value = unwrapState(value)

	if isControlObject(value) then
		return nil
	end

	if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
		return tostring(value)
	end

	if isTable(value) then
		local saved = {}
		for key, selected in pairs(value) do
			if (type(key) == "string" or type(key) == "number") and type(selected) == "boolean" then
				saved[tostring(key)] = selected
			elseif type(key) == "number" and type(selected) == "string" then
				saved[selected] = true
			end
		end
		return saved
	end

	return nil
end

local function loadVisibility(obj, value)
	if not isTable(value) or value.Visible == nil then
		return
	end

	local visible = toBoolean(unwrapState(value.Visible))
	if visible ~= nil then
		callMethod(obj, "SetVisiblity", visible)
	end
end

local function sanitizeConfigName(name)
	name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
	name = name:gsub("[/\\:*?\"<>|]", "_")
	name = name:gsub("%.%.", "_")
	return name
end

local function makeFolderTree(path)
	path = tostring(path or ""):gsub("\\", "/"):gsub("/+$", "")
	local current = ""

	for part in path:gmatch("[^/]+") do
		current = current == "" and part or (current .. "/" .. part)
		if not isfolder(current) then
			makefolder(current)
		end
	end
end

local function ensureFolders()
	local folder = tostring(SaveManager.Folder or "plaguecheat"):gsub("\\", "/"):gsub("/+$", "")
	if folder ~= "" and not isfolder(folder) then
		makeFolderTree(folder)
	end
	local configsFolder = folder .. "/configs"
	if not isfolder(configsFolder) then
		makeFolderTree(configsFolder)
	end
end

local function debugWarn(...)
	if SaveManager.Debug then
		warn(...)
	end
end

local function applyObjectValue(key, objectInfo, value)
	local parser = (SaveManager.Parser and SaveManager.Parser[objectInfo.Type])
	if not parser then
		debugWarn("SaveManager has no parser for " .. tostring(key) .. " (" .. tostring(objectInfo.Type) .. ")")
		return false
	end

	local loaded, err = pcall(parser.Load, objectInfo.Object, value)
	if not loaded then
		warn("SaveManager failed to load " .. tostring(key) .. ": " .. tostring(err))
		return false
	end

	debugWarn("SaveManager loaded " .. tostring(key))
	return true
end

SaveManager.Parser = {
	Toggle = {
		Save = function(obj)
			local state = toBoolean(callMethod(obj, "Get"))
			local binded = toBoolean(callMethod(obj, "GetBindedState"))
			local visible = toBoolean(callMethod(obj, "GetVisiblity") or callMethod(obj, "GetVisibility"))
			local colored = toBoolean(callMethod(obj, "GetColorState"))
			local col = callMethod(obj, "GetColor")
			local alpha = callMethod(obj, "GetAlpha")

			return {
				State = state == nil and false or state,
				Bind = callMethod(obj, "GetBind"),
				Binded = binded == nil and false or binded,
				Mode = callMethod(obj, "GetBindMode") or "Toggle",
				Visible = visible == nil and true or visible,
				Colored = colored == nil and false or colored,
				Color = col and { col.R, col.G, col.B } or nil,
				Alpha = alpha
			}
		end,

		Load = function(obj, value)
			local state
			if isTable(value) and value.State ~= nil then
				state = toBoolean(unwrapState(value.State))
			else
				state = toBoolean(unwrapState(value))
			end

			if state ~= nil then
				callMethod(obj, "Set", state)
			end

			if isTable(value) then
				if value.Bind ~= nil then
					callMethod(obj, "SetBind", type(value.Bind) == "string" and value.Bind or nil)
				end

				if value.Binded ~= nil then
					local binded = toBoolean(unwrapState(value.Binded))
					if binded ~= nil then
						callMethod(obj, "SetBindedState", binded)
					end
				end

				if type(value.Mode) == "string" then
					callMethod(obj, "SetBindMode", value.Mode)
				end

				if value.Colored ~= nil then
					local colored = toBoolean(unwrapState(value.Colored))
					if colored ~= nil then
						callMethod(obj, "SetColorState", colored)
					end
				end

				if value.Color ~= nil then
					local col = value.Color
					if isTable(col) then
						local r = tonumber(col[1] or col.R or col.r) or 1
						local g = tonumber(col[2] or col.G or col.g) or 1
						local b = tonumber(col[3] or col.B or col.b) or 1
						callMethod(obj, "SetColor", Color3.new(r, g, b))
					end
				end

				if value.Alpha ~= nil then
					local a = tonumber(unwrapState(value.Alpha))
					if a ~= nil then
						callMethod(obj, "SetAlpha", a)
					end
				end

				loadVisibility(obj, value)
			end
		end
	},

	Slider = {
		Save = function(obj)
			return {
				State = callMethod(obj, "Get"),
				Visible = callMethod(obj, "GetVisiblity") or callMethod(obj, "GetVisibility")
			}
		end,

		Load = function(obj, value)
			local state
			if isTable(value) and value.State ~= nil then
				state = unwrapState(value.State)
			else
				state = unwrapState(value)
			end

			if state ~= nil then
				callMethod(obj, "Set", state)
			end
			loadVisibility(obj, value)
		end,
	},

	Dropdown = {
		Save = function(obj)
			local state = toSavedSelection(callMethod(obj, "Get"))

			return {
				State = state,
				Visible = callMethod(obj, "GetVisiblity") or callMethod(obj, "GetVisibility")
			}
		end,

		Load = function(obj, value)
			local state
			if isTable(value) and value.State ~= nil then
				state = unwrapState(value.State)
			else
				state = unwrapState(value)
			end

			if state ~= nil then
				callMethod(obj, "Set", state)
			end
			loadVisibility(obj, value)
		end
	},

	Listbox = {
		Save = function(obj)
			local state = toSavedSelection(callMethod(obj, "Get"))

			return {
				State = state,
				Visible = callMethod(obj, "GetVisiblity") or callMethod(obj, "GetVisibility")
			}
		end,

		Load = function(obj, value)
			local state
			if isTable(value) and value.State ~= nil then
				state = unwrapState(value.State)
			else
				state = unwrapState(value)
			end

			if state ~= nil then
				callMethod(obj, "Set", state)
			end
			loadVisibility(obj, value)
		end
	},

	Textbox = {
		Save = function(obj)
			return {
				State = callMethod(obj, "Get"),
				Visible = callMethod(obj, "GetVisiblity") or callMethod(obj, "GetVisibility")
			}
		end,

		Load = function(obj, value)
			local state
			if isTable(value) and value.State ~= nil then
				state = unwrapState(value.State)
			else
				state = unwrapState(value)
			end

			if state ~= nil then
				callMethod(obj, "Set", state)
			end
			loadVisibility(obj, value)
		end
	},

	ColorPicker = {
		Save = function(obj)
			local color = callMethod(obj, "Get") or Color3.new(1, 1, 1)
			local alpha = callMethod(obj, "GetAlpha") or 1
			local visible = toBoolean(callMethod(obj, "GetVisiblity") or callMethod(obj, "GetVisibility"))

			return {
				Color = { color.R, color.G, color.B },
				Alpha = alpha,
				Visible = visible == nil and true or visible
			}
		end,

		Load = function(obj, value)
			if isTable(value) then
				if value.Color ~= nil then
					local col = value.Color
					if isTable(col) then
						local r = tonumber(col[1] or col.R or col.r) or 1
						local g = tonumber(col[2] or col.G or col.g) or 1
						local b = tonumber(col[3] or col.B or col.b) or 1
						callMethod(obj, "Set", Color3.new(r, g, b))
					end
				end

				if value.Alpha ~= nil then
					local a = tonumber(unwrapState(value.Alpha))
					if a ~= nil then
						callMethod(obj, "SetAlpha", a)
					end
				end

				loadVisibility(obj, value)
			end
		end
	}
}

function SaveManager:SetFolder(folder)
	self.Folder = tostring(folder or "plaguecheat"):gsub("\\", "/"):gsub("/+$", "")
	ensureFolders()
end

function SaveManager:Register(name, object, type)
	if not name or name == "" then return end
	if self.Ignore[name] then return end

	self.Objects[name] = {
		Object = object,
		Type = type
	}

	if self.Pending[name] ~= nil then
		applyObjectValue(name, self.Objects[name], self.Pending[name])
		self.Pending[name] = nil
	end
end

function SaveManager:SetDebug(enabled)
	self.Debug = enabled == true
end

function SaveManager:Save(name)
	name = sanitizeConfigName(name)
	name = name:gsub("%.[jJ][sS][oO][nN]$", "")
	if name == "" then return false end
	ensureFolders()
	local data = {}

	for key, v in pairs(self.Objects) do
		if not self.Ignore[key] then
			local parser = self.Parser[v.Type]
			if parser then
				local ok, result = pcall(parser.Save, v.Object)
				if ok then
					data[key] = result
				end
			end
		end
	end

	local folder = tostring(self.Folder or SaveManager.Folder or "plaguecheat"):gsub("\\", "/"):gsub("/+$", "")
	local path = folder .. "/configs/" .. name .. ".json"

	local ok, encoded = pcall(function()
		return httpService:JSONEncode(data)
	end)

	if ok then
		writefile(path, encoded)
		warn("SaveManager: Saved config '" .. name .. "' to " .. path)
		return true
	else
		warn("SaveManager: Failed to encode config '" .. name .. "': " .. tostring(encoded))
		return false
	end
end

function SaveManager:Load(name)
	name = sanitizeConfigName(name)
	name = name:gsub("%.[jJ][sS][oO][nN]$", "")
	if name == "" then return false end
	local folder = tostring(self.Folder or SaveManager.Folder or "plaguecheat"):gsub("\\", "/"):gsub("/+$", "")
	local path = folder .. "/configs/" .. name .. ".json"
	if not isfile(path) then
		warn("SaveManager: Config not found: " .. path)
		return false
	end

	local raw = readfile(path)

	local ok, decoded = pcall(function()
		return httpService:JSONDecode(raw)
	end)

	if not ok then
		warn("SaveManager: Failed to decode " .. path .. ": " .. tostring(decoded))
		return false
	end

	local loadedCount = 0
	local pendingCount = 0
	for key, value in pairs(decoded) do
		local obj = self.Objects[key]
		if obj then
			if applyObjectValue(key, obj, value) then
				loadedCount = loadedCount + 1
			end
		else
			self.Pending[key] = value
			pendingCount = pendingCount + 1
		end
	end

	warn("SaveManager: Loaded config '" .. name .. "' (" .. tostring(loadedCount) .. " applied, " .. tostring(pendingCount) .. " pending)")
	return true
end

function SaveManager:Delete(name)
	name = sanitizeConfigName(name)
	name = name:gsub("%.[jJ][sS][oO][nN]$", "")
	if name == "" then return false end
	local folder = tostring(self.Folder or SaveManager.Folder or "plaguecheat"):gsub("\\", "/"):gsub("/+$", "")
	local path = folder .. "/configs/" .. name .. ".json"
	if isfile(path) then
		delfile(path)
		warn("SaveManager: Deleted config '" .. name .. "'")
		return true
	end
	return false
end

function SaveManager:GetConfigs()
	local list = {}
	local folder = tostring(self.Folder or SaveManager.Folder or "plaguecheat"):gsub("\\", "/"):gsub("/+$", "")
	ensureFolders()
	local path = folder .. "/configs"
	if isfolder(path) then
		for _, file in ipairs(listfiles(path)) do
			if file:sub(-5):lower() == ".json" then
				local name = file:match("([^/\\]+)%.[jJ][sS][oO][nN]$")
				if name then
					table.insert(list, name)
				end
			end
		end
	end

	return list
end

return SaveManager
