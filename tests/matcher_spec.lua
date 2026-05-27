local matcher = require("ctrlp.matcher")

describe("matcher.fuzzy_match", function()
	it("returns all items when query is empty", function()
		local items = { "a.lua", "b.lua", "c.lua" }
		local results = matcher.fuzzy_match(items, "")
		assert.are.same(items, results)
	end)

	it("returns all items when query is nil", function()
		local items = { "a.lua", "b.lua" }
		local results = matcher.fuzzy_match(items, nil)
		assert.are.same(items, results)
	end)

	it("matches filename inside nested path", function()
		local items = { "lua/ctrlp/init.lua", "README.md", "plugin/ctrlp.lua" }
		local results = matcher.fuzzy_match(items, "init")
		assert.are.same({ "lua/ctrlp/init.lua" }, results)
	end)

	it("is case-insensitive", function()
		local items = { "README.md", "init.lua" }
		local results = matcher.fuzzy_match(items, "readme")
		assert.are.same({ "README.md" }, results)
	end)

	it("returns empty when nothing matches", function()
		local items = { "a.lua", "b.lua" }
		local results = matcher.fuzzy_match(items, "zzz")
		assert.are.same({}, results)
	end)

	it("sorts by score (exact match first)", function()
		local items = { "init.lua", "reinit.lua", "lua/ctrlp/init.lua" }
		local results = matcher.fuzzy_match(items, "init")
		-- 精确匹配 "init.lua" 应该排在最前面（因为加了 100 分）
		assert.are.equal("init.lua", results[1])
	end)

	it("matches query across path separators", function()
		local items = { "a/b/c/d.lua", "x/y/z.lua" }
		local results = matcher.fuzzy_match(items, "d.lua")
		assert.are.same({ "a/b/c/d.lua" }, results)
	end)
end)

describe("matcher.score", function()
	it("returns 0 when query longer than string", function()
		assert.are.equal(0, matcher.score("ab", "abc"))
	end)

	it("returns 0 when a character is missing", function()
		assert.are.equal(0, matcher.score("abc", "d"))
	end)

	it("returns positive score for simple match", function()
		assert.is_true(matcher.score("init.lua", "init") > 0)
	end)

	it("gives higher score for exact match", function()
		local score_partial = matcher.score("reinit.lua", "init")
		local score_exact = matcher.score("init.lua", "init")
		assert.is_true(score_exact > score_partial)
	end)
end)
