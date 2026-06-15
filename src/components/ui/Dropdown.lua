local DropdownMenu = {}

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local UserInputService = cloneref(game:GetService("UserInputService"))
local Mouse = cloneref(game:GetService("Players")).LocalPlayer:GetMouse()
local Camera = cloneref(game:GetService("Workspace")).CurrentCamera

local CurrentCamera = workspace.CurrentCamera

local CreateInput = require("./Input").New

local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

local TabBackgroundTransparency = 0.67

function DropdownMenu.New(Config, Dropdown, Element, CanCallback, Type)
	local DropdownModule = {}

	if not Dropdown.Callback then
		Type = "Menu"
	end

	Dropdown.UIElements.UIListLayout = New("UIListLayout", {
		Padding = UDim.new(0, Element.MenuPadding / 1.5),
		FillDirection = "Vertical",
		HorizontalAlignment = "Center",
	})

	Dropdown.UIElements.Menu = Creator.NewRoundFrame(Element.MenuCorner, "Squircle", {
		ThemeTag = {
			ImageColor3 = "DropdownBackground",
		},
		ImageTransparency = 1, -- 0.05
		Size = UDim2.new(1, 0, 1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
	}, {
		New("UIPadding", {
			PaddingTop = UDim.new(0, Element.MenuPadding),
			PaddingLeft = UDim.new(0, Element.MenuPadding),
			PaddingRight = UDim.new(0, Element.MenuPadding),
			PaddingBottom = UDim.new(0, Element.MenuPadding),
		}),
		New("UIListLayout", {
			FillDirection = "Vertical",
			Padding = UDim.new(0, Element.MenuPadding),
		}),
		New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, Dropdown.SearchBarEnabled and -Element.MenuPadding - Element.SearchBarHeight),
			--Name = "CanvasGroup",
			ClipsDescendants = true,
			LayoutOrder = 999,
			Name = "Frame",
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Element.MenuCorner - Element.MenuPadding),
			}),
			New("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, 0),
				ScrollBarThickness = 0,
				ScrollingDirection = "Y",
				AutomaticCanvasSize = "Y",
				CanvasSize = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				ScrollBarImageTransparency = 1,
			}, {
				Dropdown.UIElements.UIListLayout,
			}),
		}),
	})

	Dropdown.UIElements.MenuCanvas = New("Frame", {
		Size = UDim2.new(0, Dropdown.MenuWidth, 0, 300),
		BackgroundTransparency = 1,
		Position = UDim2.new(-10, 0, -10, 0),
		Visible = false,
		Active = false,
		--GroupTransparency = 1, -- 0
		Parent = Config.WindUI.DropdownGui,
		AnchorPoint = Vector2.new(1, 0),
	}, {
		Dropdown.UIElements.Menu,
		New("UISizeConstraint", {
			MinSize = Vector2.new(170, 0),
			MaxSize = Vector2.new(300, 400),
		}),
	})

	-- Canvas sizing is owned by the ScrollingFrame's AutomaticCanvasSize = "Y";
	-- the old manual RecalculateCanvasSize() forced an extra synchronous layout flush per call
	-- (and ran per-item), so it was removed in favor of the engine's built-in canvas auto-sizing.

	local function RecalculateListSize()
		local MaxHeight = Config.WindUI.DropdownGui.AbsoluteSize.Y

		local ContentY = Dropdown.UIElements.UIListLayout.AbsoluteContentSize.Y / Config.UIScale
		local SearchBarOffset = Dropdown.SearchBarEnabled and (Element.SearchBarHeight + (Element.MenuPadding * 3))
			or (Element.MenuPadding * 2)
		local TotalY = ContentY + SearchBarOffset

		if TotalY > MaxHeight then
			Dropdown.UIElements.MenuCanvas.Size =
				UDim2.fromOffset(Dropdown.UIElements.MenuCanvas.AbsoluteSize.X, MaxHeight)
		else
			Dropdown.UIElements.MenuCanvas.Size =
				UDim2.fromOffset(Dropdown.UIElements.MenuCanvas.AbsoluteSize.X, TotalY)
		end
	end

	function UpdatePosition()
		local button = Dropdown.UIElements.Dropdown or Dropdown.DropdownFrame.UIElements.Main
		local menu = Dropdown.UIElements.MenuCanvas

		local availableSpaceBelow = Camera.ViewportSize.Y
			- (button.AbsolutePosition.Y + button.AbsoluteSize.Y)
			- Element.MenuPadding
			- 54
		local requiredSpace = menu.AbsoluteSize.Y + Element.MenuPadding

		local offset = -54 -- topbar offset
		if availableSpaceBelow < requiredSpace then
			offset = requiredSpace - availableSpaceBelow - 54
		end

		menu.Position = UDim2.new(
			0,
			button.AbsolutePosition.X + button.AbsoluteSize.X,
			0,
			button.AbsolutePosition.Y + button.AbsoluteSize.Y - offset + (Element.MenuPadding * 2)
		)
	end

	local SearchLabel

	function DropdownModule:Display()
		local Values = Dropdown.Values
		local Str = ""

		if Dropdown.Multi then
			local selected = {}
			if typeof(Dropdown.Value) == "table" then
				for _, item in ipairs(Dropdown.Value) do
					local title = typeof(item) == "table" and item.Title or item
					selected[title] = true
				end
			end

			for _, value in ipairs(Values) do
				local title = typeof(value) == "table" and value.Title or value
				if selected[title] then
					Str = Str .. title .. ", "
				end
			end

			if #Str > 0 then
				Str = Str:sub(1, #Str - 2)
			end
		else
			Str = typeof(Dropdown.Value) == "table" and (Dropdown.Value.Title or Dropdown.Value[1])
				or Dropdown.Value
				or ""
		end

		if Dropdown.UIElements.Dropdown then
			Dropdown.UIElements.Dropdown.Frame.Frame.TextLabel.Text = (Str == "" and "--" or Str)
		end
	end

	local function Callback(customCallback)
		DropdownModule:Display()
		if Dropdown.Callback then
			task.spawn(function()
				Creator.SafeCallback(Dropdown.Callback, Dropdown.Value)
			end)
		else
			task.spawn(function()
				Creator.SafeCallback(customCallback)
			end)
		end
	end

	function DropdownModule:LockValues(lockedItems)
		if not lockedItems then
			return
		end

		for _, tab in next, Dropdown.Tabs do
			if tab and tab.UIElements and tab.UIElements.TabItem then
				local itemName = tab.Name
				local isLocked = false

				for _, lockedItem in next, lockedItems do
					if itemName == lockedItem then
						isLocked = true
						break
					end
				end

				if isLocked then
					Tween(tab.UIElements.TabItem, 0.1, { ImageTransparency = 1 }):Play()
					--Tween(tab.UIElements.TabItem.Highlight, 0.1, { ImageTransparency = 1 }):Play()
					Tween(tab.UIElements.TabItem.Frame.Title.TextLabel, 0.1, { TextTransparency = 0.6 }):Play()
					if tab.UIElements.TabIcon then
						Tween(tab.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0.6 }):Play()
					end

					tab.UIElements.TabItem.Active = false
					tab.Locked = true
				else
					if tab.Selected then
						Tween(tab.UIElements.TabItem, 0.1, { ImageTransparency = TabBackgroundTransparency }):Play()
						--Tween(tab.UIElements.TabItem.Highlight, 0.1, { ImageTransparency = 0.75 }):Play()
						Tween(tab.UIElements.TabItem.Frame.Title.TextLabel, 0.1, { TextTransparency = 0 }):Play()
						if tab.UIElements.TabIcon then
							Tween(tab.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0 }):Play()
						end
					else
						Tween(tab.UIElements.TabItem, 0.1, { ImageTransparency = 1 }):Play()
						--Tween(tab.UIElements.TabItem.Highlight, 0.1, { ImageTransparency = 1 }):Play()
						Tween(
							tab.UIElements.TabItem.Frame.Title.TextLabel,
							0.1,
							{ TextTransparency = Type == "Dropdown" and 0.4 or 0.05 }
						):Play()
						if tab.UIElements.TabIcon then
							Tween(
								tab.UIElements.TabIcon.ImageLabel,
								0.1,
								{ ImageTransparency = Type == "Dropdown" and 0.2 or 0 }
							):Play()
						end
					end

					tab.UIElements.TabItem.Active = true
					tab.Locked = false
				end
			end
		end
	end

	-- Lazy + chunked item building.
	-- `built` stays false until the menu is first opened (or refreshed after being opened),
	-- so a CLOSED dropdown — the common state at load — creates ZERO item instances. A dropdown
	-- with tens of thousands of values therefore adds ~0 cost to the initial UI build; the items
	-- are streamed in chunks on first Open() so opening a huge list never freezes a frame either.
	local built = false
	local refreshGeneration = 0

	local function BuildItems()
		built = true
		-- Each (re)build gets a generation token; a superseding build (or a destroyed window)
		-- aborts an in-flight chunked build cleanly at the next chunk boundary.
		refreshGeneration = refreshGeneration + 1
		local thisGeneration = refreshGeneration

		for _, Elementt in next, Dropdown.UIElements.Menu.Frame.ScrollingFrame:GetChildren() do
			if not Elementt:IsA("UIListLayout") then
				Elementt:Destroy()
			end
		end

		Dropdown.Tabs = {}

		if Dropdown.SearchBarEnabled then
			if not SearchLabel then
				SearchLabel = CreateInput("Search...", "search", Dropdown.UIElements.Menu, nil, function(val)
					local query = string.lower(val)
					for _, tab in next, Dropdown.Tabs do
						tab.UIElements.TabItem.Visible = string.find(string.lower(tab.Name), query, 1, true) ~= nil
					end
					RecalculateListSize()
				end, true)
				SearchLabel.Size = UDim2.new(1, 0, 0, Element.SearchBarHeight)
				SearchLabel.Position = UDim2.new(0, 0, 0, 0)
				SearchLabel.Name = "SearchBar"
			end
		end

		local Values = Dropdown.Values

		-- O(1) selection lookup (was an O(N) scan per item → O(N²) selection cost on build).
		local selectedNames
		if Dropdown.Multi and typeof(Dropdown.Value) == "table" then
			selectedNames = {}
			for _, item in ipairs(Dropdown.Value) do
				selectedNames[typeof(item) == "table" and item.Title or item] = true
			end
		end
		local singleValue = typeof(Dropdown.Value) == "table" and Dropdown.Value.Title or Dropdown.Value

		-- Capture keys in iteration order so chunked building preserves the original ordering.
		local orderedKeys = {}
		for k in next, Values do
			orderedKeys[#orderedKeys + 1] = k
		end

		local CHUNK_SIZE = 50

		task.spawn(function()
			for batchStart = 1, #orderedKeys, CHUNK_SIZE do
				for offset = 0, CHUNK_SIZE - 1 do
					local Index = orderedKeys[batchStart + offset]
					if Index == nil then
						break
					end
					local Tab = Values[Index]
					if Tab.Type ~= "Divider" then
						local TabMain = {
							Name = typeof(Tab) == "table" and Tab.Title or Tab,
							Desc = typeof(Tab) == "table" and Tab.Desc or nil,
							Icon = typeof(Tab) == "table" and Tab.Icon or nil,
							IconSize = typeof(Tab) == "table" and Tab.IconSize or nil,
							Original = Tab,
							Selected = false,
							Locked = typeof(Tab) == "table" and Tab.Locked or false,
							UIElements = {},
						}
						local TabIcon
						if TabMain.Icon then
							TabIcon = Creator.Image(TabMain.Icon, TabMain.Icon, 0, Config.Window.Folder, "Dropdown", true)
							TabIcon.Size =
								UDim2.new(0, TabMain.IconSize or Element.TabIcon, 0, TabMain.IconSize or Element.TabIcon)
							TabIcon.ImageLabel.ImageTransparency = Type == "Dropdown" and 0.2 or 0
							TabMain.UIElements.TabIcon = TabIcon
						end

						-- Description label is built only when there IS a description (was always built).
						local DescLabel = TabMain.Desc
							and New("TextLabel", {
								Text = TabMain.Desc,
								TextXAlignment = "Left",
								FontFace = Font.new(Creator.Font, Enum.FontWeight.Regular),
								ThemeTag = {
									TextColor3 = "Text",
									BackgroundColor3 = "Text",
								},
								TextSize = 15,
								BackgroundTransparency = 1,
								TextTransparency = Type == "Dropdown" and 0.6 or 0.35,
								LayoutOrder = 999,
								AutomaticSize = "Y",
								TextWrapped = true,
								Size = UDim2.new(1, 0, 0, 0),
								Name = "Desc",
							})
							or nil

						TabMain.UIElements.TabItem = Creator.NewRoundFrame(
							Element.MenuCorner - Element.MenuPadding,
							"Squircle",
							{
								Size = UDim2.new(1, 0, 0, 36),
								AutomaticSize = TabMain.Desc and "Y",
								ImageTransparency = 1,
								Parent = Dropdown.UIElements.Menu.Frame.ScrollingFrame,
								ThemeTag = {
									ImageColor3 = "DropdownTabBackground",
								},
								Active = not TabMain.Locked,
							},
							{
								New("Frame", {
									Size = UDim2.new(1, 0, 1, 0),
									BackgroundTransparency = 1,
								}, {
									New("UIListLayout", {
										Padding = UDim.new(0, Element.TabPadding),
										FillDirection = "Horizontal",
										VerticalAlignment = "Center",
									}),
									New("UIPadding", {
										PaddingTop = UDim.new(0, Element.TabPadding),
										PaddingLeft = UDim.new(0, Element.TabPadding),
										PaddingRight = UDim.new(0, Element.TabPadding),
										PaddingBottom = UDim.new(0, Element.TabPadding),
									}),
									TabIcon,
									New("Frame", {
										Size = UDim2.new(1, TabIcon and -Element.TabPadding - Element.TabIcon or 0, 0, 0),
										BackgroundTransparency = 1,
										AutomaticSize = "Y",
										Name = "Title",
									}, {
										New("TextLabel", {
											Text = TabMain.Name,
											TextXAlignment = "Left",
											FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
											ThemeTag = {
												TextColor3 = "Text",
												BackgroundColor3 = "Text",
											},
											TextSize = 15,
											BackgroundTransparency = 1,
											TextTransparency = Type == "Dropdown" and 0.4 or 0.05,
											LayoutOrder = 999,
											AutomaticSize = "Y",
											Size = UDim2.new(1, 0, 0, 0),
										}),
										DescLabel,
										New("UIListLayout", {
											Padding = UDim.new(0, Element.TabPadding / 3),
											FillDirection = "Vertical",
										}),
									}),
								}),
							},
							true
						)

						if TabMain.Locked then
							TabMain.UIElements.TabItem.Frame.Title.TextLabel.TextTransparency = 0.6
							if TabMain.UIElements.TabIcon then
								TabMain.UIElements.TabIcon.ImageLabel.ImageTransparency = 0.6
							end
						end

						if Dropdown.Multi then
							TabMain.Selected = selectedNames ~= nil and selectedNames[TabMain.Name] == true
						else
							TabMain.Selected = singleValue == TabMain.Name
						end

						if TabMain.Selected and not TabMain.Locked then
							TabMain.UIElements.TabItem.ImageTransparency = TabBackgroundTransparency
							TabMain.UIElements.TabItem.Frame.Title.TextLabel.TextTransparency = 0
							if TabMain.UIElements.TabIcon then
								TabMain.UIElements.TabIcon.ImageLabel.ImageTransparency = 0
							end
						end

						Dropdown.Tabs[Index] = TabMain

						if Type == "Dropdown" then
							Creator.AddSignal(TabMain.UIElements.TabItem.MouseButton1Click, function()
								if TabMain.Locked then
									return
								end

								if Dropdown.Multi then
									if not TabMain.Selected then
										TabMain.Selected = true
										Tween(
											TabMain.UIElements.TabItem,
											0.1,
											{ ImageTransparency = TabBackgroundTransparency }
										):Play()
										--Tween(TabMain.UIElements.TabItem.Highlight, 0.1, { ImageTransparency = 0.75 }):Play()
										Tween(TabMain.UIElements.TabItem.Frame.Title.TextLabel, 0.1, { TextTransparency = 0 }):Play()
										if TabMain.UIElements.TabIcon then
											Tween(TabMain.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0 }):Play()
										end
										table.insert(Dropdown.Value, TabMain.Original)
									else
										if not Dropdown.AllowNone and #Dropdown.Value == 1 then
											return
										end
										TabMain.Selected = false
										Tween(TabMain.UIElements.TabItem, 0.1, { ImageTransparency = 1 }):Play()
										--Tween(TabMain.UIElements.TabItem.Highlight, 0.1, { ImageTransparency = 1 }):Play()
										Tween(TabMain.UIElements.TabItem.Frame.Title.TextLabel, 0.1, { TextTransparency = 0.4 }):Play()
										if TabMain.UIElements.TabIcon then
											Tween(TabMain.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0.2 }):Play()
										end

										for i, v in next, Dropdown.Value do
											if typeof(v) == "table" and (v.Title == TabMain.Name) or (v == TabMain.Name) then
												table.remove(Dropdown.Value, i)
												break
											end
										end
									end
								else
									for Index, TabPisun in next, Dropdown.Tabs do
										Tween(TabPisun.UIElements.TabItem, 0.1, { ImageTransparency = 1 }):Play()
										--Tween(TabPisun.UIElements.TabItem.Highlight, 0.1, { ImageTransparency = 1 }):Play()
										Tween(
											TabPisun.UIElements.TabItem.Frame.Title.TextLabel,
											0.1,
											{ TextTransparency = 0.4 }
										):Play()
										if TabPisun.UIElements.TabIcon then
											Tween(TabPisun.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0.2 }):Play()
										end
										TabPisun.Selected = false
									end
									TabMain.Selected = true
									Tween(TabMain.UIElements.TabItem, 0.1, { ImageTransparency = TabBackgroundTransparency }):Play()
									--Tween(TabMain.UIElements.TabItem.Highlight, 0.1, { ImageTransparency = 0.75 }):Play()
									Tween(TabMain.UIElements.TabItem.Frame.Title.TextLabel, 0.1, { TextTransparency = 0 }):Play()
									if TabMain.UIElements.TabIcon then
										Tween(TabMain.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0 }):Play()
									end
									Dropdown.Value = TabMain.Original
								end
								Callback()
							end)
						elseif Type == "Menu" then
							if not TabMain.Locked then
								Creator.AddSignal(TabMain.UIElements.TabItem.MouseEnter, function()
									Tween(TabMain.UIElements.TabItem, 0.08, { ImageTransparency = TabBackgroundTransparency }):Play()
								end)
								Creator.AddSignal(TabMain.UIElements.TabItem.InputEnded, function()
									Tween(TabMain.UIElements.TabItem, 0.08, { ImageTransparency = 1 }):Play()
								end)
							end
							Creator.AddSignal(TabMain.UIElements.TabItem.MouseButton1Click, function()
								if TabMain.Locked then
									return
								end
								Callback(Tab.Callback or function() end)
							end)
						end
					else
						require("../../elements/Divider"):New({ Parent = Dropdown.UIElements.Menu.Frame.ScrollingFrame })
					end
				end

				-- Abort if a newer build superseded this one, or the window was destroyed mid-build.
				if thisGeneration ~= refreshGeneration or Config.Window.Destroyed then
					return
				end
				if batchStart + CHUNK_SIZE <= #orderedKeys then
					task.wait()
				end
			end

			RecalculateListSize()
		end)
	end

	local function EnsureBuilt()
		if not built then
			BuildItems()
		end
	end

	function DropdownModule:Refresh(Values)
		if Config.Window.Destroyed then
			return
		end

		Dropdown.Values = Values

		-- Normalize a single-string multi value into a one-element table (was done per-item).
		if Dropdown.Multi and typeof(Dropdown.Value) == "string" then
			for _, i in next, Values do
				if typeof(i) == "table" then
					if i.Title == Dropdown.Value then
						Dropdown.Value = { i }
					end
				else
					if i == Dropdown.Value then
						Dropdown.Value = { Dropdown.Value }
					end
				end
			end
		end

		-- Popup width is item-independent; set it now so the menu is correctly sized when shown.
		Dropdown.UIElements.MenuCanvas.Size = UDim2.new(
			0,
			Dropdown.MenuWidth + 6 + 6 + 5 + 5 + 18 + 6 + 6,
			Dropdown.UIElements.MenuCanvas.Size.Y.Scale,
			Dropdown.UIElements.MenuCanvas.Size.Y.Offset
		)

		-- Only (re)build instances if they already exist (menu opened at least once);
		-- the first build is deferred to Open() via EnsureBuilt().
		if built then
			BuildItems()
		end

		Callback()
	end

	DropdownModule:Refresh(Dropdown.Values)

	function DropdownModule:Select(Items)
		if Items then
			Dropdown.Value = Items
		else
			if Dropdown.Multi then
				Dropdown.Value = {}
			else
				Dropdown.Value = nil
			end
		end
		DropdownModule:Refresh(Dropdown.Values)
	end

	RecalculateListSize()

	function DropdownModule:Open()
		if CanCallback then
			-- Build the item rows on first open (deferred from construction) before showing.
			EnsureBuilt()
			Dropdown.UIElements.Menu.Visible = true
			Dropdown.UIElements.MenuCanvas.Visible = true
			Dropdown.UIElements.MenuCanvas.Active = true
			Dropdown.UIElements.Menu.Size = UDim2.new(1, 0, 0, 0)
			Tween(Dropdown.UIElements.Menu, 0.1, {
				Size = UDim2.new(1, 0, 1, 0),
				ImageTransparency = 0,
			}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()

			task.spawn(function()
				task.wait(0.1)
				Dropdown.Opened = true
			end)

			UpdatePosition()
		end
	end

	function DropdownModule:Close()
		Dropdown.Opened = false

		Tween(Dropdown.UIElements.Menu, 0.25, {
			Size = UDim2.new(1, 0, 0, 0),
			ImageTransparency = 1,
		}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()

		task.spawn(function()
			task.wait(0.1)
			Dropdown.UIElements.Menu.Visible = false
		end)

		task.spawn(function()
			task.wait(0.25)
			Dropdown.UIElements.MenuCanvas.Visible = false
			Dropdown.UIElements.MenuCanvas.Active = false
		end)
	end

	Creator.AddSignal(
		(
			Dropdown.UIElements.Dropdown and Dropdown.UIElements.Dropdown.MouseButton1Click
			or Dropdown.DropdownFrame.UIElements.Main.MouseButton1Click
		),
		function()
			DropdownModule:Open()
		end
	)

	Creator.AddSignal(UserInputService.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			local menuCanvas = Dropdown.UIElements.MenuCanvas
			local AbsPos, AbsSize = menuCanvas.AbsolutePosition, menuCanvas.AbsoluteSize

			local DropdownButton = Dropdown.UIElements.Dropdown or Dropdown.DropdownFrame.UIElements.Main
			local ButtonAbsPos = DropdownButton.AbsolutePosition
			local ButtonAbsSize = DropdownButton.AbsoluteSize

			local isClickOnDropdown = Mouse.X >= ButtonAbsPos.X
				and Mouse.X <= ButtonAbsPos.X + ButtonAbsSize.X
				and Mouse.Y >= ButtonAbsPos.Y
				and Mouse.Y <= ButtonAbsPos.Y + ButtonAbsSize.Y

			local isClickOnMenu = Mouse.X >= AbsPos.X
				and Mouse.X <= AbsPos.X + AbsSize.X
				and Mouse.Y >= AbsPos.Y
				and Mouse.Y <= AbsPos.Y + AbsSize.Y

			if Config.Window.CanDropdown and Dropdown.Opened and not isClickOnDropdown and not isClickOnMenu then
				DropdownModule:Close()
			end
		end
	end)

	Creator.AddSignal(
		Dropdown.UIElements.Dropdown and Dropdown.UIElements.Dropdown:GetPropertyChangedSignal("AbsolutePosition")
			or Dropdown.DropdownFrame.UIElements.Main:GetPropertyChangedSignal("AbsolutePosition"),
		UpdatePosition
	)

	return DropdownModule
end

return DropdownMenu
