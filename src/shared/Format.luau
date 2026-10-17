-- Number and text formatting for the UI.

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }

-- 1234 -> "1.23K", 5600000 -> "5.6M"
function Format.Short(n: number?): string
	local value = math.floor(n or 0)
	local negative = value < 0
	value = math.abs(value)

	local index = 1
	while value >= 1000 and index < #SUFFIXES do
		value /= 1000
		index += 1
	end

	local text
	if index == 1 then
		text = tostring(value)
	else
		if value < 10 then
			text = string.format("%.2f", value)
		elseif value < 100 then
			text = string.format("%.1f", value)
		else
			text = tostring(math.floor(value))
		end
		if text:find("%.") then
			text = (text:gsub("0+$", ""))
			text = (text:gsub("%.$", ""))
		end
	end

	return (if negative then "-" else "") .. text .. SUFFIXES[index]
end

function Format.Money(n: number?): string
	return "$" .. Format.Short(n)
end

function Format.Weight(kg: number?): string
	return string.format("%.1f kg", kg or 0)
end

return Format
