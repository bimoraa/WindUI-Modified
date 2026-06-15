local Label = {}

local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

function Label.New(Text, Icon, Parent, IsPlaceholder, Radius, RemoveGlass)
	local Radius = Radius or 10
	local IconLabelFrame
	if Icon and Icon ~= "" then
		local iconData = Creator.Icon(Icon) -- resolve once instead of 3 lookups
		IconLabelFrame = New("ImageLabel", {
			Image = iconData[1],
			ImageRectSize = iconData[2].ImageRectSize,
			ImageRectOffset = iconData[2].ImageRectPosition,
			Size = UDim2.new(0, 24 - 3, 0, 24 - 3),
			BackgroundTransparency = 1,
			ThemeTag = {
				ImageColor3 = "Icon",
			},
		})
	end

	local TextLabel = New("TextLabel", {
		BackgroundTransparency = 1,
		TextSize = 17,
		FontFace = Font.new(Creator.Font, Enum.FontWeight.Regular),
		Size = UDim2.new(1, IconLabelFrame and -29 or 0, 1, 0),
		TextXAlignment = "Left",
		ThemeTag = {
			TextColor3 = IsPlaceholder and "Placeholder" or "Text",
		},
		Text = Text,
	})

	local LabelFrame = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 42),
		Parent = Parent,
		BackgroundTransparency = 1,
		Text = "",
	}, {
		New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			Creator.NewRoundFrame(Radius, "Squircle", {
				ThemeTag = {
					ImageColor3 = "Placeholder",
				},
				Size = UDim2.new(1, 0, 1, 0),
				ImageTransparency = 0.85,
			}),
			not RemoveGlass and Creator.NewRoundFrame(Radius, "SquircleGlass", {
				ThemeTag = {
					ImageColor3 = "Outline",
				},
				Size = UDim2.new(1, 1, 1, 1),
				ImageTransparency = 0.9,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
			}) or nil,
			Creator.NewRoundFrame(Radius, "Squircle", {
				Size = UDim2.new(1, 0, 1, 0),
				Name = "Frame",
				ThemeTag = {
					ImageColor3 = "LabelBackground",
					ImageTransparency = "LabelBackgroundTransparency",
				},
				-- ImageColor3 = Color3.new(1,1,1),
				-- ImageTransparency = .95
			}, {
				New("UIPadding", {
					PaddingLeft = UDim.new(0, 12),
					PaddingRight = UDim.new(0, 12),
				}),
				New("UIListLayout", {
					FillDirection = "Horizontal",
					Padding = UDim.new(0, 8),
					VerticalAlignment = "Center",
					HorizontalAlignment = "Left",
				}),
				IconLabelFrame,
				TextLabel,
			}),
		}),
	})

	return LabelFrame
end

return Label
