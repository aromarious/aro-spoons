-- SpoonInstall が読む docs/docs.json を作る。各 Spoon の init.lua の先頭の説明（--- === 名前 === の次の行）と obj.version を使う
-- 使い方: lua scripts/docs.lua Source/*.spoon > docs/docs.json
local function q(s) return '"' .. s:gsub('[\\"]', '\\%0') .. '"' end
local out = {}
for _, dir in ipairs(arg) do
  local src = assert(io.open(dir .. "/init.lua")):read("a")
  local name = assert(src:match("^%-%-%- === (%S+) ==="), dir .. ": --- === 名前 === がない")
  local desc = assert(src:match("%-%-%- === %S+ ===\n%-%-%-\n%-%-%- ([^\n]+)"), dir .. ": 説明の行がない")
  local version = assert(src:match('obj%.version = "([^"]+)"'), dir .. ": obj.version がない")
  table.insert(out, string.format('  { "name": %s, "desc": %s, "version": %s, "type": "Module" }', q(name), q(desc), q(version)))
end
print("[\n" .. table.concat(out, ",\n") .. "\n]")
