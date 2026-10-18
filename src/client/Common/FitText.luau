-- Sizes a TextLabel's text to fit its box, without using TextScaled.
-- TextScaled was rendering our outlined labels far too small, so this works the
-- size out itself: as big as the box allows, capped by the label's
-- UITextSizeConstraint (MaxTextSize / MinTextSize), and shrunk if the text is
-- too wide. Updates when the box, text or font changes.
--
-- Set the attribute AutoFit = false on a label to stop it being resized.

local TextService = game:GetService("TextService")

local FitText = {}

-- Total UIScale applied to an object (UIScale scales its parent and everything
-- inside it), so we can turn on-screen pixels back into the label's own units.
local function totalScale(object: Instance): number
	local scale = 1
	local current: Instance? = object
	while current do
		local uiScale = current:FindFirstChildOfClass("UIScale")
		if uiScale then
			scale *= uiScale.Scale
		end
		current = current.Parent
	end
	return scale
end

local function plainText(label: TextLabel): string
	if label.RichText then
		return (label.Text:gsub("<[^>]->", ""))
	end
	return label.Text
end

local function measure(label: TextLabel, text: string, size: number, width: number): Vector2
	local frame = if label.TextWrapped then Vector2.new(width, math.huge) else Vector2.new(math.huge, math.huge)
	return TextService:GetTextSize(text, size, label.Font, frame)
end

local function fit(label: TextLabel)
	if label:GetAttribute("AutoFit") == false then
		return
	end
	label.TextScaled = false

	local scale = totalScale(label)
	if scale <= 0.01 then
		return
	end
	local box = label.AbsoluteSize / scale
	if box.X < 2 or box.Y < 2 then
		return
	end

	local limit = label:FindFirstChildOfClass("UITextSizeConstraint")
	local maxSize = if limit then limit.MaxTextSize else 100
	local minSize = if limit then math.max(limit.MinTextSize, 6) else 6

	-- Leave room for the outline on both sides.
	local stroke = label:FindFirstChildOfClass("UIStroke")
	local pad = if stroke and stroke.Enabled then stroke.Thickness * 2 else 0
	local width = math.max(box.X - pad, 1)
	local height = math.max(box.Y - pad, 1)

	local text = plainText(label)
	if text == "" then
		label.TextSize = math.clamp(math.floor(height), minSize, maxSize)
		return
	end

	local size = math.clamp(math.floor(height), minSize, maxSize)
	-- Step down until the text fits the box.
	while size > minSize do
		local bounds = measure(label, text, size, width)
		if bounds.X <= width + 0.5 and bounds.Y <= height + 0.5 then
			break
		end
		size -= 1
	end
	label.TextSize = size
end

function FitText.Attach(label: TextLabel)
	if label:GetAttribute("FitTextAttached") then
		return
	end
	label:SetAttribute("FitTextAttached", true)
	local function refit()
		fit(label)
	end
	for _, property in { "AbsoluteSize", "Text", "Font", "TextWrapped", "RichText" } do
		label:GetPropertyChangedSignal(property):Connect(refit)
	end
	label:GetAttributeChangedSignal("AutoFit"):Connect(refit)
	-- Size limits may be changed after the label is made (Dialogue does this).
	label.ChildAdded:Connect(function(child)
		if child:IsA("UITextSizeConstraint") then
			child.Changed:Connect(refit)
			refit()
		end
	end)
	local limit = label:FindFirstChildOfClass("UITextSizeConstraint")
	if limit then
		limit.Changed:Connect(refit)
	end
	refit()
end

return FitText
