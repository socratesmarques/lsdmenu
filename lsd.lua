if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer
while not localPlayer do
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	localPlayer = Players.LocalPlayer
end

local function chooseGuiParent()
	if type(gethui) == "function" then
		local ok, result = pcall(gethui)
		if ok and result then return result end
	end
	local ok, coreGui = pcall(game.GetService, game, "CoreGui")
	if ok and coreGui then return coreGui end
	return localPlayer:WaitForChild("PlayerGui")
end

local guiParent = chooseGuiParent()
local previous = guiParent:FindFirstChild("lsd")
if previous then
	local oldCleanup = previous:FindFirstChild("Cleanup")
	if oldCleanup and oldCleanup:IsA("BindableEvent") then oldCleanup:Fire() end
	previous:Destroy()
end

local connections, humanoids, visuals = {}, {}, {}
local alive = true
local state = {aim = false, mobileAim = false, chams = false, boxes = false, holding = false}
local accent = Color3.fromRGB(170, 85, 255)
local inactive = Color3.fromRGB(39, 39, 49)

local function make(className, properties, parent)
	local object = Instance.new(className)
	for key, value in pairs(properties) do object[key] = value end
	object.Parent = parent
	return object
end

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local gui = make("ScreenGui", {
	Name = "lsd",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)

local cleanupEvent = make("BindableEvent", {Name = "Cleanup"}, gui)
local window = make("Frame", {
	Name = "Window",
	Size = UDim2.fromOffset(350, 315),
	Position = UDim2.new(0.5, -175, 0.5, -157),
	BackgroundColor3 = Color3.fromRGB(23, 23, 30),
	BorderSizePixel = 0,
	Active = true,
}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 12)}, window)
local border = make("UIStroke", {Color = accent, Thickness = 2}, window)

local title = make("TextLabel", {
	Size = UDim2.new(1, -52, 0, 44),
	Position = UDim2.fromOffset(14, 0),
	BackgroundTransparency = 1,
	Text = "lsd",
	TextColor3 = accent,
	TextSize = 25,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Active = true,
}, window)

local function createButton(parent, text)
	local button = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = inactive,
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = Color3.fromRGB(245, 245, 250),
		TextSize = 14,
		Font = Enum.Font.Gotham,
		AutoButtonColor = true,
	}, parent)
	make("UICorner", {CornerRadius = UDim.new(0, 7)}, button)
	return button
end

local closeButton = createButton(window, "×")
closeButton.Size = UDim2.fromOffset(34, 34)
closeButton.Position = UDim2.new(1, -41, 0, 5)
closeButton.TextSize = 22

local tabBar = make("Frame", {
	Position = UDim2.fromOffset(12, 49),
	Size = UDim2.new(1, -24, 0, 36),
	BackgroundTransparency = 1,
}, window)
make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5)}, tabBar)

local pages, tabButtons, toggleButtons = {}, {}, {}
local selectedTab = 1

local function updateTheme()
	border.Color = accent
	title.TextColor3 = accent
	for index, button in ipairs(tabButtons) do
		button.BackgroundColor3 = index == selectedTab and accent or inactive
		pages[index].Visible = index == selectedTab
	end
	for button, key in pairs(toggleButtons) do
		button.BackgroundColor3 = state[key] and accent or inactive
	end
end

for index, name in ipairs({"Mira", "Visual", "Configurações"}) do
	local tabIndex = index
	local button = createButton(tabBar, name)
	button.Size = UDim2.new(1 / 3, -4, 1, 0)
	tabButtons[index] = button

	local page = make("Frame", {
		Position = UDim2.fromOffset(14, 99),
		Size = UDim2.new(1, -28, 1, -113),
		BackgroundTransparency = 1,
		Visible = index == 1,
	}, window)
	make("UIListLayout", {Padding = UDim.new(0, 9)}, page)
	pages[index] = page

	connect(button.Activated, function()
		selectedTab = tabIndex
		updateTheme()
	end)
end

local function createToggle(page, label, key)
	local button = createButton(page, label .. ": OFF")
	toggleButtons[button] = key
	connect(button.Activated, function()
		state[key] = not state[key]
		button.Text = label .. (state[key] and ": ON" or ": OFF")
		updateTheme()
	end)
end

createToggle(pages[1], "Aimbot (players + NPCs)", "aim")
createToggle(pages[1], "Mira fixa (celular)", "mobileAim")
make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 62),
	BackgroundTransparency = 1,
	Text = "PC: segure E. Celular: ative Mira fixa.\nAlvo visível mais próximo do centro da tela.",
	TextColor3 = Color3.fromRGB(185, 185, 195),
	TextSize = 12,
	TextWrapped = true,
	Font = Enum.Font.Gotham,
}, pages[1])

createToggle(pages[2], "Chams", "chams")
createToggle(pages[2], "Box", "boxes")

for _, entry in ipairs({
	{"Roxo", Color3.fromRGB(170, 85, 255)},
	{"Azul", Color3.fromRGB(60, 150, 255)},
	{"Verde", Color3.fromRGB(50, 200, 120)},
	{"Rosa", Color3.fromRGB(240, 85, 155)},
}) do
	local color = entry[2]
	local button = createButton(pages[3], entry[1])
	connect(button.Activated, function()
		accent = color
		updateTheme()
	end)
end
updateTheme()

local dragInput, dragOrigin, windowOrigin
connect(title.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragInput, dragOrigin, windowOrigin = input, input.Position, window.Position
	end
end)
connect(UIS.InputChanged, function(input)
	if not dragInput then return end
	local mouseMove = dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement
	if input == dragInput or mouseMove then
		local delta = input.Position - dragOrigin
		window.Position = UDim2.new(windowOrigin.X.Scale, windowOrigin.X.Offset + delta.X, windowOrigin.Y.Scale, windowOrigin.Y.Offset + delta.Y)
	end
end)
connect(UIS.InputEnded, function(input)
	if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then dragInput = nil end
	if input.KeyCode == Enum.KeyCode.E then state.holding = false end
end)
connect(UIS.InputBegan, function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.E then state.holding = true end
end)
connect(UIS.WindowFocusReleased, function()
	state.holding, dragInput = false, nil
end)

local function register(object)
	if object:IsA("Humanoid") then humanoids[object] = true end
end
for _, object in ipairs(workspace:GetDescendants()) do register(object) end
connect(workspace.DescendantAdded, register)
connect(workspace.DescendantRemoving, function(object)
	if humanoids[object] then humanoids[object] = nil end
end)

local function removeVisual(model)
	local visual = visuals[model]
	if not visual then return end
	if visual.highlight then visual.highlight:Destroy() end
	if visual.box then visual.box:Destroy() end
	visuals[model] = nil
end

local function getVisual(model)
	if visuals[model] then return visuals[model] end
	local highlight = make("Highlight", {
		Adornee = model,
		Enabled = false,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		FillTransparency = 0.65,
		OutlineTransparency = 0,
	}, gui)
	local box = make("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false}, gui)
	local outline = make("UIStroke", {Thickness = 1.5, Color = accent}, box)
	visuals[model] = {highlight = highlight, box = box, outline = outline}
	return visuals[model]
end

local function drawBox(camera, model, box)
	local ok, cf, size = pcall(model.GetBoundingBox, model)
	if not ok then box.Visible = false return end
	local half = size / 2
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
	for x = -1, 1, 2 do
		for y = -1, 1, 2 do
			for z = -1, 1, 2 do
				local point = cf:PointToWorldSpace(Vector3.new(half.X * x, half.Y * y, half.Z * z))
				local screen = camera:WorldToViewportPoint(point)
				if screen.Z <= 0 then box.Visible = false return end
				minX, minY = math.min(minX, screen.X), math.min(minY, screen.Y)
				maxX, maxY = math.max(maxX, screen.X), math.max(maxY, screen.Y)
			end
		end
	end
	local viewport = camera.ViewportSize
	box.Visible = maxX >= 0 and maxY >= 0 and minX <= viewport.X and minY <= viewport.Y
	box.Position = UDim2.fromOffset(minX, minY)
	box.Size = UDim2.fromOffset(maxX - minX, maxY - minY)
end

local renderBinding = "lsd_" .. HttpService:GenerateGUID(false)
RunService:BindToRenderStep(renderBinding, Enum.RenderPriority.Camera.Value + 1, function()
	if not alive then return end
	local camera = workspace.CurrentCamera
	if not camera then return end

	local activeModels = {}
	local closestHead, closestDistance = nil, 250
	local aiming = state.aim and (state.holding or state.mobileAim) and not UIS:GetFocusedTextBox()
	local screenCenter = camera.ViewportSize / 2
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = localPlayer.Character and {localPlayer.Character} or {}

	for humanoid in pairs(humanoids) do
		local model = humanoid.Parent
		if not model or not model:IsA("Model") or model == localPlayer.Character or humanoid.Health <= 0 then continue end
		local head = model:FindFirstChild("Head")
		if not head or not head:IsA("BasePart") then continue end
		activeModels[model] = true

		if state.chams or state.boxes then
			local visual = getVisual(model)
			visual.highlight.Enabled = state.chams
			visual.highlight.FillColor, visual.highlight.OutlineColor = accent, accent
			visual.outline.Color = accent
			visual.box.Visible = false
			if state.boxes then drawBox(camera, model, visual.box) end
		end

		if aiming then
			local screen, visible = camera:WorldToViewportPoint(head.Position)
			if visible then
				local distance = (Vector2.new(screen.X, screen.Y) - screenCenter).Magnitude
				if distance < closestDistance then
					local origin = camera.CFrame.Position
					local hit = workspace:Raycast(origin, head.Position - origin, rayParams)
					if not hit or hit.Instance:IsDescendantOf(model) then
						closestHead, closestDistance = head, distance
					end
				end
			end
		end
	end

	for model, visual in pairs(visuals) do
		if not activeModels[model] then
			removeVisual(model)
		else
			visual.highlight.Enabled = state.chams
			if not state.boxes then visual.box.Visible = false end
		end
	end

	if closestHead then camera.CFrame = CFrame.lookAt(camera.CFrame.Position, closestHead.Position) end
end)

local function stop()
	if not alive then return end
	alive = false
	RunService:UnbindFromRenderStep(renderBinding)
	for _, connection in ipairs(connections) do connection:Disconnect() end
	for model in pairs(visuals) do removeVisual(model) end
end

cleanupEvent.Event:Connect(stop)
gui.Destroying:Connect(stop)
connect(closeButton.Activated, function()
	stop()
	gui:Destroy()
end)

print("[lsd] carregado: jogadores e NPCs com Humanoid/Head")
