--Cutscene Plugin by Ozzypig
--February 2012

manager = PluginManager()
plugin = manager:CreatePlugin()
toolbar = plugin:CreateToolbar("Cutscenes")
button5 = toolbar:CreateButton("", "Create new cutscene track", "film_add.png")
button6 = toolbar:CreateButton("", "Toggles cutscene track editor", "film_edit.png")
button = toolbar:CreateButton("", "Find all shotdata children of selected object and play as a cutscene track", "film_go.png")
button2 = toolbar:CreateButton("", "Clone the CurrentCamera for use in a cutscene track", "camera_add.png")
button3 = toolbar:CreateButton("", "Create a LocalScript that plays a cutscene track", "script_player_camera_add.png")
button4 = toolbar:CreateButton("", "Insert a customizable button script that plays a cutscene track", "brick_script_player_camera_add.png")

--note:
children = function (o) local c = o:GetChildren() local n = #c local i = 0 return function () i = i + 1 if i <= n then return i, c[i] end end end
serv = setmetatable({}, {__index = function (serv, key) if not rawget(serv,key) then serv[key] = game:GetService(key) end return rawget(serv,key) end})
selection = serv.Selection
insert = serv.InsertService

--------------------------------------------------

editor_active = false

colors = {
	black = Color3.new(0, 0, 0);
	grey = Color3.new(.5, .5, .5);
	white = Color3.new(1, 1, 1);
	red = Color3.new(1, .25, .25);
	green = Color3.new(.25, 1, .25);
	blue = Color3.new(.25, .25, 1);
}

gui = Instance.new("ScreenGui", serv.CoreGui)
gui.Name = "CutsceneCreatorGui"
container = Instance.new("Frame", gui)
--container.Text = ""
--container.AutoButtonColor = false
container.BackgroundTransparency = 1
container.Size = UDim2.new(1, 0, 1, 0)
container.Visible = false
ribbon = Instance.new("TextButton", container)
ribbon.Size = UDim2.new(1, 0, 0, 101)
ribbon.Position = UDim2.new(0, 0, 0, -1)
ribbon.BorderSizePixel = 0
ribbon.Text = ""
ribbon.AutoButtonColor = false
ribbon.BackgroundColor3 = colors.black
ribbon.BackgroundTransparency = 0.5
props = Instance.new("TextButton", ribbon)
props.Size = UDim2.new(0, 90, 0, 90)
props.Position = UDim2.new(0, 5, 0, 5)
props.BorderSizePixel = 0
props.Text = ""
props.AutoButtonColor = false
props.BackgroundColor3 = colors.black
props.BackgroundTransparency = 0
props.ClipsDescendants = true
timeline = Instance.new("TextButton", ribbon)
timeline.Size = UDim2.new(1, -110, 0, 90)
timeline.Position = UDim2.new(0, 100, 0, 5)
timeline.ClipsDescendants = true
timeline.BorderSizePixel = 0
timeline.Text = ""
timeline.AutoButtonColor = false
timeline.BackgroundColor3 = colors.black
timeline.BackgroundTransparency = 0

function selectShot(i, shot)
	props:ClearAllChildren()
	local y = 5
	local recall = Instance.new("TextButton", props)
	recall.BackgroundColor3 = colors.black
	recall.BorderSizePixel = 1
	recall.BorderColor3 = colors.grey
	recall.TextColor3 = colors.white
	recall.Text = "Recall"
	recall.Font = "Arial"
	recall.FontSize = "Size12"
	recall.Size = UDim2.new(0, 35, 0, 12) 
	recall.Position = UDim2.new(0, 2, 0, y)
	recall.MouseButton1Down:connect(function ()
		print("Recalling shot")
		workspace.CurrentCamera:Destroy() wait(0.1)
		local cam = workspace.CurrentCamera
		cam.CoordinateFrame = shot.CoordinateFrame
		cam.Focus = shot.Focus
		cam.FieldOfView = shot.FieldOfView
	end)
	local replace = Instance.new("TextButton", props)
	replace.BackgroundColor3 = colors.black
	replace.BorderSizePixel = 1
	replace.BorderColor3 = colors.grey
	replace.TextColor3 = colors.white
	replace.Text = "Replace"
	replace.Font = "Arial"
	replace.FontSize = "Size12"
	replace.Size = UDim2.new(0, 38, 0, 12) 
	replace.Position = UDim2.new(0, 40, 0, y)
	replace.MouseButton1Down:connect(function ()
		print("Replaced shot")
		local newshot = getShotDataFromCamera(workspace.CurrentCamera)
		for k, v in pairs(newshot) do
			shot[k] = v
		end
	end)
	
	y = y + 12 + 5
	local fov_label = Instance.new("TextLabel", props)
	fov_label.BackgroundColor3 = colors.black
	fov_label.BorderSizePixel = 0
	fov_label.TextColor3 = colors.white
	fov_label.Text = "FOV: "
	fov_label.Font = "Arial"
	fov_label.FontSize = "Size12"
	fov_label.Position = UDim2.new(0, 0, 0, y)
	fov_label.TextXAlignment = "Left"
	fov_label.TextYAlignment = "Top"
	local fov_field = Instance.new("TextBox", props)
	fov_field.ClearTextOnFocus = false
	fov_field.BackgroundColor3 = colors.black
	fov_field.BorderSizePixel = 1
	fov_field.BorderColor3 = colors.white
	fov_field.TextColor3 = colors.white
	fov_field.Font = "Arial"
	fov_field.FontSize = "Size12"
	fov_field.Position = UDim2.new(0, 25, 0, y)
	fov_field.TextXAlignment = "Left"
	fov_field.TextYAlignment = "Top"
	fov_field.Size = UDim2.new(1, -30, 0, 12)
	local fov_value = shot.FieldOfView
	local function updateFov() fov_field.Text = math.floor(fov_value + 0.5) end
	updateFov()
	fov_field.Changed:connect(function (p)
		if p == "Text" then
			local n = tonumber(fov_field.Text)
			if n then
				fov_value = math.min(80, math.max(20, n))
				--print("FOV changed to: " .. fov_value)
			end
			updateFov()
		end
	end)
	y = y + 12 + 5
end

function setupEditor(cutscene_track)
	local shots = {}
	for i, v in children(cutscene_track) do
		local n = tonumber(v.Name)
		if n then
			local shot = getShotFromShotData(v)
			shots[n] = shot
		end
	end
	for i, shot in ipairs(shots) do
		local b = Instance.new("TextButton", timeline)
		b.AutoButtonColor = false
		b.TextColor3 = colors.white
		b.BorderColor3 = colors.grey
		b.BackgroundColor3 = colors.black
		b.BorderSizePixel = 1
		b.Text = "Shot " .. i
		b.MouseEnter:connect(function () b.BorderColor3 = colors.white end)
		b.MouseLeave:connect(function () b.BorderColor3 = colors.grey end)
		b.Size = UDim2.new(0, 80, 0, 80)
		b.Position = UDim2.new(0, 5 + (i - 1) * 85, 0, 5)
		b.MouseButton1Down:connect(function ()
			selectShot(i, shot)
		end)
	end
end

selection.SelectionChanged:connect(function ()
	timeline:ClearAllChildren()
	props:ClearAllChildren()
	if not editor_active then return end
	local sel = selection:Get()
	if not sel[1] then return end
	if not sel[1]:FindFirstChild("CutsceneTrack") then return end
	setupEditor(sel[1])
end)

--------------------------------------------------

localscript_str = [=[wait()

--Insert a model called "Track" in here with the shots you've taken.
--This script simply plays back the track for the respective player.

--Start from the original camera position (ie, looking at the player)
from_original_camera_position = true

--Tween back to original camera position
to_original_camera_position = true

--Don't allow player to walk during the cutscene?
freeze_player = true

--Show a GUI? (set to nil if no)
gui = nil --script.CutsceneGui

--Remove GUI when finished?
remove_gui = true

children = function (o) local c = o:GetChildren() local n = #c local i = 0 return function () i = i + 1 if i <= n then return i, c[i] end end end]=]

playback_code = [=[

interpolate = {}

function interpolate.linear(a, t, n0)
	local n0 = n0 or 1
	local v0 = t[n0]
	local v1 = t[n0 + 1] or t[n0]
	return v0 * (1 - a) + v1 * a
end

function interpolate.cosine(a, t, n0)
	local n0 = n0 or 1
	local v0 = t[n0]
	local v1 = t[n0 + 1] or t[n0]
	local f = (1 - math.cos(a * math.pi)) * .5
	return v0 * (1 - f) + v1 * f
end

function interpolate.cubic(a, t, n1)
	local n1 = n1 or 2
	local v0 = t[n1 - 1] or t[n1]
	local v1 = t[n1]
	local v2 = t[n1 + 1] or t[n1]
	local v3 = t[n1 + 2] or t[n1]
	local P = (v3 - v2) - (v0 - v1)
	local Q = (v0 - v1) - P
	local R = v2 - v0
	local S = v1
	return P * math.pow(a, 3) + Q * math.pow(a, 2) + R * a + S
end

function thread(func)
	coroutine.resume(coroutine.create(func))
end

function interpolateV3(func, a, t, n)
	local xs = {}
	local ys = {}
	local zs = {}
	for i, v in ipairs(t) do
		table.insert(xs, v.x)
		table.insert(ys, v.y)
		table.insert(zs, v.z)
	end
	return Vector3.new(func(a, xs, n), func(a, ys, n), func(a, zs, n))
end

function interpolateCF(func, a, t, n)
	local ps = {}
	local lvs = {}
	for i, v in ipairs(t) do
		table.insert(ps, v.p)
		table.insert(lvs, v.lookVector)
	end
	local p = interpolateV3(func, a, ps, n)
	local lv = interpolateV3(func, a, lvs, n)
	return CFrame.new(p, p + lv)
end

function getInterpolator(name)
	if interpolate[name] then
		return interpolate[name]
	else
		print("Unknown interpolator " .. name)
		return interpolate.cosine
	end
end

function playTrack(camera, track)
	--print("Playing track with " .. tostring(camera) .. " and " .. #track .. " shots")
	--track is a table of shots
	local cf = camera.CoordinateFrame
	local fc = camera.Focus
	local fov = camera.FieldOfView
	local free_mode = false
	local focus_part = camera.CameraSubject
	if camera.CameraSubject then free_mode = false end
	local enabled = true
	thread(function ()
		local lfov = fov
		while enabled do
			camera.CoordinateFrame = cf
			if free_mode then
				focus_part.CFrame = fc
			else
				camera.Focus = fc
			end
			camera.FieldOfView = math.max(20, math.min(80, fov))
			wait()
		end
	end)
	local cfs = {}
	local fcs = {}
	local fovs = {}
	for i, v in pairs(track) do
		table.insert(cfs, v.CoordinateFrame)
		table.insert(fcs, v.Focus)
		table.insert(fovs, v.FieldOfView)
	end
	for n = 1, #track - 1 do
		--print("Shot " .. n .. " to " .. (n + 1))
		local shot_this = track[n]
		--local shot_next = track[n + 1] or track[n]
		--print("Waiting " .. shot_this.Time)
		wait(shot_this.Time)
		local inter = getInterpolator(shot_this.TweenMode)
		local time_start = tick()
		local time = shot_this.TweenTime
		--print("Tweening...")
		while tick() < time_start + time do
			local a = (tick() - time_start) / time
			
			--do the interpolation
			cf = interpolateCF(inter, a, cfs, n)
			fc = interpolateCF(inter, a, fcs, n)
			fov = interpolate.cosine(a, fovs, n)
			
			wait()
		end
		--print("Done")
	end
	enabled = false
end

function newShot(cf, focus, fov, time, tweenmode, tweentime)
	return {
		CoordinateFrame = cf;
		Focus = focus;
		FieldOfView = fov;
		Time = time;
		TweenMode = tweenmode;
		TweenTime = tweentime;
	}
end

function getShotFromShotData(camera)
	local time = 0
	local tweentime = 2
	local fov = 60
	local tweenmode = "cosine"
	local cf = CFrame.new(0, 0, 0)
	local fc = CFrame.new(0, 0, 1)
	
	if camera:FindFirstChild("STime") then					time = camera.STime.Value end
	if camera:FindFirstChild("STweenTime") then			tweentime = camera.STweenTime.Value end
	if camera:FindFirstChild("SFOV") then					fov = camera.SFOV.Value end
	if camera:FindFirstChild("STweenMode") then			tweenmode = camera.STweenMode.Value end
	if camera:FindFirstChild("SCoordinateFrame") then	cf = camera.SCoordinateFrame.Value end
	if camera:FindFirstChild("SFocus") then 				fc = camera.SFocus.Value end
	
	return newShot(cf, fc, fov, time, tweenmode, tweentime)
end

function getFocusPart()
	local p = Instance.new("Part", workspace)
	p.Anchored = true
	p.FormFactor = Enum.FormFactor.Custom
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Transparency = 1
	return p
end]=]

localscript_str = localscript_str .. playback_code .. ([=[

function getTrack(p)
	if not p then print("Nothing selected") return end
	local shots = {}
	for k, v in children(p) do
		local n = tonumber(v.Name)
		if n then
			local shot = getShotFromShotData(v)
			shots[n] = shot
		end
	end
	local cc = workspace.CurrentCamera
	local current_shot = newShot(cc.CoordinateFrame, cc.Focus, cc.FieldOfView, 0, "cosine", 2.5)
	if from_original_camera_position then
		table.insert(shots, 1, current_shot)
	end
	if to_original_camera_position then
		table.insert(shots, current_shot)
	end
	local focus_part = getFocusPart()
	focus_part.CFrame = cc.Focus
	--focus_part.Parent = cc
	workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
	cc.CameraSubject = focus_part
	--[[local nc = Instance.new("Camera", workspace)
	workspace.CurrentCamera = nc
	cc:Destroy()]]
	local player = game.Players.LocalPlayer
	local char = player.Character
	local ws
	if freeze_player then
		ws = char.Humanoid.WalkSpeed
		char.Torso.Anchored = true
		char.Humanoid.WalkSpeed = 0
		char.Humanoid.PlatformStand = true
	end
	local ngui
	if gui then
		ngui = gui:clone()
		ngui.Parent = player.PlayerGui
	end
	playTrack(workspace.CurrentCamera, shots)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	workspace.CurrentCamera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid
	focus_part:Destroy()
	if freeze_player then
		char.Humanoid.WalkSpeed = ws
		char.Torso.Anchored = false
		char.Humanoid.PlatformStand = false
	end
	if ngui and remove_gui then
		ngui:Destroy()
	end
end

getTrack(script.Track)

script:Destroy()]=])

buttonscript_str = [=[
--name of cutscene
cutscene_id = "Cutscene1"

--"infinite"	= show whenever button is pressed
--"spawn"		= show once per spawn
--"enter"		= show once per gameplay
show_rule = "enter"

--if show_rule is "infinite", how long after the end of showing the cutscene can they see it again?
debounce_time = 1

----------------------------------------

button = script.Parent
ls = button.CutsceneLocalScript

d = false

function showCutscene(player, sync)
	local n = ls:clone()
	n.Parent = player.Backpack
	if not sync then while n.Parent do wait() end end
end

function getTags(p)
	local cs = p:FindFirstChild("Cutscenes")
	if not cs then
		cs = Instance.new("IntValue", p)
		cs.Name = "Cutscenes"
	end
	return cs
end

function checkTag(p)
	return getTags(p):FindFirstChild(cutscene_id)
end

function setTag(p)
	local t = Instance.new("IntValue", getTags(p))
	t.Name = cutscene_id
end

function hasSeenCutsceneEnter(player) return checkTag(player) end
function hasSeenCutsceneSpawn(player) return checkTag(player.Character) end

function recSeenCutsceneEnter(player) setTag(player) end
function recSeenCutsceneSpawn(player) setTag(player.Character) end

function onTouch(part)
	--get player
	local player = game.Players:GetPlayerFromCharacter(part.Parent)
	if not player then return end
	--check already watching
	if player.Backpack:FindFirstChild(ls.Name) then return end
	--check debounce
	if d then return end d = true

	if show_rule == "enter" then
		if not hasSeenCutsceneEnter(player) then
			showCutscene(player)
			recSeenCutsceneEnter(player)
		end
	elseif show_rule == "spawn" then
		if not hasSeenCutsceneSpawn(player) then
			showCutscene(player)
			recSeenCutsceneSpawn(player)
		end
	else
		showCutscene(player)
		wait(debounce_time)
	end

	d = false
end

button.Touched:connect(onTouch)]=]

--------------------------------------------------

local s, e = loadstring(playback_code)
if not s then error("playback_code: " .. e) end
s()

function getShotDataFromCamera(cam)
	local new = Instance.new("IntValue")
	new.Name = "CutsceneFrame"

	local stweenmode = Instance.new("StringValue", new)
	stweenmode.Name = "STweenMode"
	stweenmode.Value = "cubic"
	
	local sfov = Instance.new("NumberValue", new)
	sfov.Name = "SFOV"
	sfov.Value = cam.FieldOfView
	
	local stime = Instance.new("NumberValue", new)
	stime.Name = "STime"
	stime.Value = 0
	
	local stweentime = Instance.new("NumberValue", new)
	stweentime.Name = "STweenTime"
	stweentime.Value = 2
	
	local scf = Instance.new("CFrameValue", new)
	scf.Name = "SCoordinateFrame"
	scf.Value = cam.CoordinateFrame
	
	local sfc = Instance.new("CFrameValue", new)
	sfc.Name = "SFocus"
	sfc.Value = cam.Focus

	return new
end

function getTrack(p)
	if not p then print("Nothing selected") return end
	local shots = {}
	for k, v in children(p) do
		local n = tonumber(v.Name)
		if n then
			local shot = getShotFromShotData(v)
			shots[n] = shot
		end
	end
	local cc = workspace.CurrentCamera
	local current_shot = newShot(cc.CoordinateFrame, cc.Focus, cc.FieldOfView, 0, "cosine", 2.5)
	if from_original_camera_position then
		table.insert(shots, 1, current_shot)
	end
	if to_original_camera_position then
		table.insert(shots, current_shot)
	end
	
	local ct = cc.CameraType
	local cf = cc.CoordinateFrame
	local fc = cc.Focus
	local fov = cc.FieldOfView
	
	local focus_part = getFocusPart()
	focus_part.CFrame = cc.Focus
	--focus_part.Parent = cc
	cc.CameraType = Enum.CameraType.Fixed
	cc.CameraSubject = focus_part
	playTrack(workspace.CurrentCamera, shots)
	focus_part:Destroy()
	
	workspace.CurrentCamera = Instance.new("Camera", workspace) wait()
	cc = workspace.CurrentCamera
	cc.CameraType = ct
	cc.CoordinateFrame = cf
	cc.Focus = fc
	cc.FieldOfView = fov
end

button.Click:connect(function ()
	print("Playing shots...")
	getTrack(selection:Get()[1])
	print("Done")
end)

button2.Click:connect(function ()
	local cam = workspace.CurrentCamera
	local sel = selection:Get()
	if #sel >= 1 then
		if sel[1]:IsA("Camera") then
			cam = sel[1]
		end
	end
	
	local new = getShotDataFromCamera(cam)
	new.Parent = cam.Parent
	wait()
	selection:Set{new}
end)

button3.Click:connect(function ()
	local sel = selection:Get()
	local m
	if sel[1] then m = sel[1] else m = Instance.new("Model") end
	m = m:clone()
	m.Name = "Track"
	local ls = Instance.new("LocalScript")
	ls.Source = localscript_str
	ls.Name = "CutsceneLocalScript"
	ls.Parent = workspace
	m.Parent = ls
	selection:Set{ls}
end)

button4.Click:connect(function ()
	local sel = selection:Get()
	local p
	if sel[1] then p = sel[1] else p = workspace end
	
	local s = Instance.new("Script")
	s.Source = buttonscript_str
	s.Parent = p
	s.Name = "CutsceneButtonScript"
	
	selection:Set{s}
end)

button5.Click:connect(function ()
	local m = Instance.new("Model", workspace)
	m.Name = "Track"
	local s = Instance.new("IntValue", m)
	s.Name = "CutsceneTrack"
	editor_active = true
	updateEditor()
	selection:Set{m}
end)

function updateEditor()
	container.Visible = editor_active
	timeline:ClearAllChildren()
	props:ClearAllChildren()
end

button6.Click:connect(function ()
	editor_active = not editor_active
	updateEditor()
end)
