-- 色の計算（hs を使わないので test.lua から確かめられる）
-- 色は Hammerspoon の色の表（{ white = 0.5 } か { red =, green =, blue = }）
local M = {}

-- "#RRGGBB" の形にする
function M.hex(c)
  local function h(v) return string.format("%02X", math.floor((v or 0) * 255 + 0.5)) end
  if c.white then return "#" .. h(c.white):rep(3) end
  return "#" .. h(c.red) .. h(c.green) .. h(c.blue)
end

-- 色の明るさ（WCAG の相対輝度）とコントラスト比
function M.relLum(c)
  local function lin(v) v = v or 0; return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
  if c.white then return lin(c.white) end
  return 0.2126 * lin(c.red) + 0.7152 * lin(c.green) + 0.0722 * lin(c.blue)
end
function M.contrast(a, b)
  local l1, l2 = M.relLum(a), M.relLum(b)
  if l1 < l2 then l1, l2 = l2, l1 end
  return (l1 + 0.05) / (l2 + 0.05)
end

-- 背景 bg の上で読める文字色にする。c が無いときと、灰色系で 4.5:1 に届かないときは fallback（テーマの文字色）にする。
-- 色味のある色（リンクの青など）は、toWhite なら白へ、そうでなければ黒へ少しずつ寄せて 4.5:1 にする
function M.readable(c, bg, fallback, toWhite)
  if not c then return fallback end
  if M.contrast(c, bg) >= 4.5 then return c end
  local r, g, b = c.red or c.white, c.green or c.white, c.blue or c.white
  if math.max(r, g, b) - math.min(r, g, b) < 0.15 then return fallback end
  local to = toWhite and 1 or 0
  local k, out = 0, c
  repeat
    k = k + 0.1
    out = { red = r + (to - r) * k, green = g + (to - g) * k, blue = b + (to - b) * k }
  until M.contrast(out, bg) >= 4.5 or k >= 1
  return out
end

return M
