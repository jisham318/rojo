local Rojo = script:FindFirstAncestor("Rojo")
local Plugin = Rojo.Plugin
local Packages = Rojo.Packages

local Roact = require(Packages.Roact)
local Flipper = require(Packages.Flipper)

local Theme = require(Plugin.App.Theme)
local Assets = require(Plugin.Assets)
local bindingUtil = require(Plugin.App.bindingUtil)
local getTextBoundsAsync = require(Plugin.App.getTextBoundsAsync)

local SlicedImage = require(script.Parent.SlicedImage)
local TouchRipple = require(script.Parent.TouchRipple)

local SPRING_PROPS = {
	frequency = 5,
	dampingRatio = 1,
}

local e = Roact.createElement

local TextButton = Roact.Component:extend("TextButton")

function TextButton:init()
	self.motor = Flipper.GroupMotor.new({
		hover = 0,
		enabled = self.props.enabled and 1 or 0,
	})
	self.binding = bindingUtil.fromMotor(self.motor)
end

function TextButton:didUpdate(lastProps)
	if lastProps.enabled ~= self.props.enabled then
		self.motor:setGoal({
			enabled = Flipper.Spring.new(self.props.enabled and 1 or 0),
		})
	end
end

function TextButton:render()
	return Theme.with(function(theme)
		local textBounds = getTextBoundsAsync(self.props.text, theme.Font.Main, theme.TextSize.Large, math.huge)

		local style = self.props.style

		local buttonTheme = theme.Button[style]

		local bindingHover = bindingUtil.deriveProperty(self.binding, "hover")
		local bindingEnabled = bindingUtil.deriveProperty(self.binding, "enabled")

		return e("ImageButton", {
			Size = UDim2.new(0, (theme.TextSize.Body * 2) + textBounds.X, 0, 34),
			Position = self.props.position,
			AnchorPoint = self.props.anchorPoint,

			LayoutOrder = self.props.layoutOrder,
			BackgroundTransparency = 1,

			[Roact.Event.Activated] = self.props.onClick,

			[Roact.Event.MouseEnter] = function()
				self.motor:setGoal({
					hover = Flipper.Spring.new(1, SPRING_PROPS),
				})
			end,

			[Roact.Event.MouseLeave] = function()
				self.motor:setGoal({
					hover = Flipper.Spring.new(0, SPRING_PROPS),
				})
			end,
		}, {
			TouchRipple = e(TouchRipple, {
				color = buttonTheme.ActionFillColor,
				transparency = self.props.transparency:map(function(value)
					return bindingUtil.blendAlpha({ buttonTheme.ActionFillTransparency, value })
				end),
				zIndex = 2,
			}),

			Text = e("TextLabel", {
				Text = self.props.text,
				FontFace = theme.Font.Main,
				TextSize = theme.TextSize.Large,
				TextColor3 = bindingUtil.mapLerp(
					bindingEnabled,
					buttonTheme.Enabled.TextColor,
					buttonTheme.Disabled.TextColor
				),
				TextTransparency = self.props.transparency,

				Size = UDim2.new(1, 0, 1, 0),

				BackgroundTransparency = 1,
			}),

			Border = style == "Bordered" and e(SlicedImage, {
				slice = Assets.Slices.RoundedBorder,
				color = bindingUtil.mapLerp(
					bindingEnabled,
					buttonTheme.Enabled.BorderColor,
					buttonTheme.Disabled.BorderColor
				),
				transparency = self.props.transparency,

				size = UDim2.new(1, 0, 1, 0),

				zIndex = 0,
			}),

			HoverOverlay = e(SlicedImage, {
				slice = Assets.Slices.RoundedBackground,
				color = buttonTheme.ActionFillColor,
				transparency = Roact.joinBindings({
					hover = bindingHover:map(function(value)
						return 1 - value
					end),
					transparency = self.props.transparency,
				}):map(function(values)
					return bindingUtil.blendAlpha({
						buttonTheme.ActionFillTransparency,
						values.hover,
						values.transparency,
					})
				end),

				size = UDim2.new(1, 0, 1, 0),

				zIndex = -1,
			}),

			Background = style == "Solid" and e(SlicedImage, {
				slice = Assets.Slices.RoundedBackground,
				color = bindingUtil.mapLerp(
					bindingEnabled,
					buttonTheme.Enabled.BackgroundColor,
					buttonTheme.Disabled.BackgroundColor
				),
				transparency = self.props.transparency,

				size = UDim2.new(1, 0, 1, 0),

				zIndex = -2,
			}),

			Children = Roact.createFragment(self.props[Roact.Children]),
		})
	end)
end

return TextButton
