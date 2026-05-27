local M = {}

function M.fuzzy_match(items, query)
	if query == "" or not query then
		return items
	end

	query = query:lower()
	local scored = {}

	for _, item in ipairs(items) do
		local lower = item:lower()
		local score = M.score(lower, query)
		if score > 0 then
			table.insert(scored, { item = item, score = score })
		end
	end

	table.sort(scored, function(a, b)
		return a.score > b.score
	end)

	local results = {}
	for _, s in ipairs(scored) do
		table.insert(results, s.item)
	end
	return results
end

function M.score(str, query)
	local str_len = #str
	local q_len = #query
	if q_len > str_len then
		return 0
	end

	local score = 0
	local s_idx = 1
	local consecutive = 0
	local first_match = true

	for q_idx = 1, q_len do
		local qc = query:sub(q_idx, q_idx)
		local found = false

		while s_idx <= str_len do
			local sc = str:sub(s_idx, s_idx)
			if sc == qc then
				if first_match then
					score = score + 20
					first_match = false
				else
					score = score + 10
				end

				if s_idx == 1 or str:sub(s_idx - 1, s_idx - 1) == "/" then
					score = score + 15
				end

				consecutive = consecutive + 1
				if consecutive > 1 then
					score = score + 5 * consecutive
				end

				s_idx = s_idx + 1
				found = true
				break
			else
				consecutive = 0
				s_idx = s_idx + 1
			end
		end

		if not found then
			return 0
		end
	end

	if str == query then
		score = score + 100
	end

	return score
end

return M
