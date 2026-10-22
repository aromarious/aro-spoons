--- === AroCopyCard ===
---
--- コピーしたときに、全部のモニタの下の中央へ中身を見せるカードを少しの間出す（音も光もなし）
--- 文字・書式付きの文字・画像に対応。パスワード管理アプリからのコピーは中身を伏せる
--- macOS の通知ではないので集中モードでも出る。閉じるキー（既定 alt-shift-n）で消せる
---
--- 使い方:
---   hs.loadSpoon("AroCopyCard")
---   spoon.AroCopyCard:start()

local obj = {}
obj.__index = obj

obj.name = "AroCopyCard"
obj.version = "0.1"
obj.author = "aromarious"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.homepage = "https://github.com/aromarious/aro-spoons"

--- AroCopyCard.secs
--- Variable
--- カードを出しておく秒数（中身に関係なく同じ）。既定は 2
obj.secs = 2

--- AroCopyCard.fontSize
--- Variable
--- 文字の大きさ。既定は 24
obj.fontSize = 24

--- AroCopyCard.width
--- Variable
--- 1 行に並べる全角文字数の目安（長すぎる行は目で追いにくい）。既定は 40
obj.width = 40

--- AroCopyCard.maxChars
--- Variable
--- 長い中身は先頭のこの文字数だけ出す。既定は 800
obj.maxChars = 800

--- AroCopyCard.maxLines
--- Variable
--- 折り返したあと、この行数まで出す。既定は 12
obj.maxLines = 12

--- AroCopyCard.label
--- Variable
--- カードの左上に出す見出し。既定は "コピー"
obj.label = "コピー"

--- AroCopyCard.secretApps
--- Variable
--- ここに入れたアプリ（bundle ID）からのコピーは中身を伏せる。既定は 1Password・パスワード・Bitwarden
obj.secretApps = { ["com.1password.1password"] = true, ["com.agilebits.onepassword7"] = true,
  ["com.apple.Passwords"] = true, ["com.bitwarden.desktop"] = true }

--- AroCopyCard.closeKey
--- Variable
--- 出ているカードを閉じるキー。{ mods = { "alt", "shift" }, key = "n" } の形。nil なら既定の alt-shift-n
--- キーは横取りしないので、同じキーを使うほかのアプリの処理もそのまま動く
--- 閉じるキーは、カードを出すほかの Aro の Spoon と共通（最後に start した Spoon の設定になる）
obj.closeKey = nil

--- AroCopyCard.snapshotPath
--- Variable
--- 見た目の確認用。ファイルの場所を入れておくと、次に出したカードを画像に保存する
obj.snapshotPath = nil

local dir = hs.spoons.resourcePath("")
local cards = dofile(dir .. "cards.lua")
local color = dofile(dir .. "color.lua")

-- 色は出す瞬間のライト／ダークに合わせる（文字のコントラストはどちらも 4.5:1 以上）
local palette = {
  Dark = { bg = { white = 0.12, alpha = 0.92 }, edge = { white = 1, alpha = 0.10 }, text = { white = 1 }, dim = { white = 1, alpha = 0.55 } },
  Light = { bg = { white = 0.97, alpha = 0.95 }, edge = { white = 0, alpha = 0.10 }, text = { white = 0.1 }, dim = { white = 0, alpha = 0.58 } },
}
local LINE, PAD = 1.6, 28   -- 行の高さ（文字の大きさに対する倍率。日本語は 1.5〜1.8 が読みやすい）、カードの内側の余白
local function para() return { lineHeightMultiple = LINE, lineBreak = "wordWrap" } end

-- 書式付きの文字を、テーマの背景の上で読めるようにする。太字・斜体・下線・色味などの書式は残し、
-- 背景色は外す。読めない文字色の直し方は color.lua の readable
function obj:_themeStyled(st, p, dark)
  local t, out = st:asTable(), st
  for i = 2, #t do
    local a = t[i].attributes or {}
    a.backgroundColor = nil
    if a.link then   -- リンクは描くときに既定の青で上書きされるので、リンクの印を外して色と下線で表す
      a.link = nil
      a.color = a.color or { red = 0.04, green = 0.4, blue = 0.85 }
      a.underlineStyle = a.underlineStyle or 1
    end
    local c = a.color
    if c and c.white == nil and c.red == nil then c = nil end   -- 名前付きの色（「文字の色」など）は中身が取れないので、指定なしと同じに扱う
    a.color = color.readable(c, p.bg, p.text, dark)
    if a.underlineStyle and a.underlineStyle ~= 0 then a.underlineColor = a.color end   -- 下線も文字と同じ色に
    -- 文字の大きさは元に関係なく fontSize にそろえる。
    -- 書体の指定が無いとき（HTML から来た文字は明朝体の Times になる）や明朝体のときはゴシック（システムの書体）にする。太字・斜体は残す
    local fname = (a.font and a.font.name) or ""
    if fname == "" or fname:find("^Times") or fname:find("Mincho") or fname:find("明朝") then
      local bold = fname:find("Bold") or fname:find("W6") or fname:find("Black")
      if fname:find("Italic") then a.obliqueness = 0.15 end
      fname = bold and ".AppleSystemUIFontBold" or ".AppleSystemUIFont"
    end
    a.font = { name = fname, size = self.fontSize }
    a.paragraphStyle = para()
    -- asTable の表をそのまま new に渡すと位置が 1 文字ずれるので、区間ごとに書式を付け直す
    out = out:setStyle(a, t[i].starts, t[i].ends, true)
  end
  return out
end

-- 文字を折り返して出すときの行数を数える。canvas は折り返し後の大きさを測れないので、
-- 段落ごとに「この幅に収まる一番長い先頭部分」を二分探索で探して 1 行ずつ切り出す
function obj:_wrappedLines(st, width)
  local c = hs.canvas.new({ x = 0, y = 0, w = 10, h = 10 })
  local font = { name = ".AppleSystemUIFont", size = self.fontSize }
  local function w(text) return c:minimumTextSize(hs.styledtext.new(text, { font = font })).w end
  local lines = 0
  local lineH = c:minimumTextSize(hs.styledtext.new("あ", { font = font })).h * LINE
  local str = st:getString():gsub("%s+$", "")   -- 書式付きの文字は末尾に改行が付いていることが多いので、数えない
  for line in (str .. "\n"):gmatch("(.-)\n") do
    local chars = {}
    for _, cp in utf8.codes(line) do table.insert(chars, utf8.char(cp)) end
    if #chars == 0 then lines = lines + 1 end
    local i = 1
    while i <= #chars do
      local lo, hi = i, #chars       -- chars[i..lo] は必ず収まるとして、収まる最後の位置を探す
      while lo < hi do
        local mid = math.floor((lo + hi + 1) / 2)
        if w(table.concat(chars, "", i, mid)) <= width - 4 then lo = mid else hi = mid - 1 end
      end
      lines = lines + 1
      i = lo + 1
    end
  end
  c:delete()
  return lines, lineH
end

-- 長い中身は先頭だけ出す
function obj:_headOf(st)
  local n = utf8.len(st:getString()) or 0
  if n <= self.maxChars then return st end
  return st:sub(1, self.maxChars) .. hs.styledtext.new(" …", st:asTable()[2] and st:asTable()[2].attributes or {})
end

-- kind: "text"（文字だけ）/ "rich"（書式付きの文字）/ "image"（縮小して出す）
-- 文字は折り返して最大 maxLines 行まで出し、カードの高さを中身に合わせる
function obj:show(kind, payload)
  local dark = hs.host.interfaceStyle() == "Dark"
  local p = palette[dark and "Dark" or "Light"]
  local M, W, H = 16, self.fontSize * self.width + PAD * 2, 52
  local body
  if kind == "image" then
    local sz = payload:size()
    local scale = math.min(1, 360 / sz.w, 200 / sz.h)
    local iw, ih = math.max(1, sz.w * scale), math.max(1, sz.h * scale)
    W, H = math.max(240, iw + 24), ih + 50
    body = { { type = "image", image = payload, imageScaling = "scaleProportionally", frame = { x = M + (W - iw) / 2, y = M + 38, w = iw, h = ih } } }
  else
    local st
    if kind == "rich" then st = self:_headOf(self:_themeStyled(payload, p, dark))
    else st = self:_headOf(hs.styledtext.new(payload, { font = { name = ".AppleSystemUIFont", size = self.fontSize }, color = p.text, paragraphStyle = para() })) end
    local tw = W - PAD * 2
    local lines, lineH = self:_wrappedLines(st, tw)
    lines = math.min(lines, self.maxLines)
    H = PAD + 22 + lines * lineH + PAD
    body = { { type = "text", text = st, frame = { x = M + PAD, y = M + PAD + 14, w = tw, h = lines * lineH + 8 } } }
  end
  table.insert(body, 1, { type = "rectangle", frame = { x = M, y = M, w = W, h = H }, roundedRectRadii = { xRadius = 12, yRadius = 12 },
    fillColor = p.bg, strokeColor = p.edge, strokeWidth = 1,
    withShadow = true, shadow = { blurRadius = 14, color = { alpha = 0.3 }, offset = { h = -3, w = 0 } } })
  table.insert(body, 2, { type = "text", frame = { x = M + PAD, y = M + PAD - 8, w = 200, h = 22 },
    text = hs.styledtext.new(self.label, { font = { name = ".AppleSystemUIFontBold", size = 16 }, color = p.dim }) })
  local shown = cards.show({ group = "copy", W = W, H = H, M = M, at = "bottom", elements = body,
    secs = self.secs, fadeIn = 0.1, fadeOut = 0.3, closable = true })
  if self.snapshotPath and shown[1] then shown[1]:imageFromCanvas():saveToFile(self.snapshotPath) end
end

-- iPhone からのコピー（ユニバーサルクリップボード）の写真は、画像そのものではなく一時ファイルの場所（file URL）で届く。
-- そのファイルは別アプリのグループコンテナにあり、Hammerspoon にフルディスクアクセスが無いと読めない（Operation not permitted）。
-- 読めればその画像を、読めなければファイル名を返す
local function pastedFile()
  local u = hs.pasteboard.readURL()
  local path = type(u) == "table" and u.filePath
  if not path then return nil end
  local img = hs.image.imageFromPath(path)
  return img, path:match("[^/]+$")
end

function obj:_check()
  local n = hs.pasteboard.changeCount()
  if n == self._count then return end
  self._count = n
  local app = hs.application.frontmostApplication()
  if app and self.secretApps[app:bundleID() or ""] then self:show("text", "（中身は表示しません）"); return end
  local types = {}
  for _, t in ipairs(hs.pasteboard.contentTypes() or {}) do types[t] = true end
  local text = hs.pasteboard.readString()
  if types["public.rtf"] or types["public.html"] or types["com.apple.flat-rtfd"] then
    local st = hs.pasteboard.readStyledText()
    if st and #st:getString() > 0 then self:show("rich", st); return end
  end
  if text and #text > 0 then
    self:show("text", (text:gsub("[ \t]+", " "):gsub("\n\n\n+", "\n\n"):gsub("^%s+", ""):gsub("%s+$", "")))
  elseif hs.pasteboard.readImage() then
    self:show("image", hs.pasteboard.readImage())
  else
    local img, name = pastedFile()
    if img then self:show("image", img); return end
    local remote = types["com.apple.is-remote-clipboard"] and "iPhone などから" or ""
    self:show("text", name and ("（" .. remote .. "ファイル）" .. name) or "（文字以外）")
  end
end

--- AroCopyCard:start()
--- Method
--- コピーの見張りを始める（クリップボードの更新回数を 0.15 秒ごとに見る）
function obj:start()
  if self.closeKey then cards.closeKey.mods, cards.closeKey.key = self.closeKey.mods, self.closeKey.key end
  self._count = hs.pasteboard.changeCount()
  if self._timer then self._timer:stop() end
  self._timer = hs.timer.doEvery(0.15, function() self:_check() end)
  return self
end

--- AroCopyCard:stop()
--- Method
--- コピーの見張りをやめる
function obj:stop()
  if self._timer then self._timer:stop(); self._timer = nil end
  cards.close("copy")
  return self
end

return obj
