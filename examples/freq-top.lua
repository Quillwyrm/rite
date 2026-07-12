-- freq-top - print the most frequent words in a file.
-- Usage: lua examples/freq-top.lua file [count]

local args = {...}

if #args < 1 or #args > 2 then
	io.stderr:write("usage: lua examples/freq-top.lua file [count]\n")
	os.exit(1)
end

local limit = 20

if #args == 2 then
	limit = tonumber(args[2])
end

if limit == nil or limit < 0 or limit % 1 ~= 0 then
	io.stderr:write("count must be a non-negative int\n")
	os.exit(1)
end

local file, err = io.open(args[1], "rb")
if file == nil then
	io.stderr:write(tostring(err), "\n")
	os.exit(1)
end

local text = file:read("*a")
file:close()

local function split(text, sep)
	local parts = {}
	local start = 1

	while true do
		local found = string.find(text, sep, start, true)
		if found == nil then
			parts[#parts + 1] = string.sub(text, start)
			return parts
		end

		parts[#parts + 1] = string.sub(text, start, found - 1)
		start = found + #sep
	end
end

local function line_words(line)
	local words = {}

	for _, word in ipairs(split(string.lower(line), " ")) do
		if word ~= "" then
			words[#words + 1] = word
		end
	end

	return words
end

local function append_line_words(words, line)
	for _, word in ipairs(line_words(line)) do
		words[#words + 1] = word
	end

	return words
end

local function count_word(counts, word)
	counts[word] = (counts[word] or 0) + 1
	return counts
end

local words = {}
for _, line in ipairs(split(text, "\n")) do
	append_line_words(words, line)
end

local counts = {}
for _, word in ipairs(words) do
	count_word(counts, word)
end

local ranked = {}
for word, count in pairs(counts) do
	ranked[#ranked + 1] = {word, count}
end

table.sort(ranked, function(a, b)
	if a[2] ~= b[2] then
		return a[2] > b[2]
	end

	return a[1] < b[1]
end)

local printed = 0
for _, entry in ipairs(ranked) do
	if printed >= limit then
		break
	end

	printed = printed + 1
	io.write(printed, ". ", entry[2], " ", entry[1], "\n")
end
