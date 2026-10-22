-- カードを画面に表示する部分。出す・時間がたったら消す・閉じるキーで消す・ほかのカードと重ならない位置に置く
-- カードの中身（見た目）は呼ぶ側が作って show に渡す
-- Spoon にするときは、このファイルを各 Spoon にそのまま写す。Spoon をいくつ入れても動く表示する部分が 1 つになるよう、
-- package.loaded["aro.cards"] を見て、置かれているものが自分以上の版ならそれを使い、自分のほうが新しければ入れ物はそのままで関数だけ差し替える
-- 版を上げても、古い Spoon が呼ぶ関数の名前と引数は変えない（足すのはよい）
local VERSION = 1

local shared = package.loaded["aro.cards"]
if shared and shared.version >= VERSION then return shared end
local C = shared or {}   -- 差し替えのときも、出ているカード・閉じるキーの設定・見張りは前のものを使い続ける
C.version = VERSION

-- 出ているカードを閉じるキー。使う側で closeKey.mods と closeKey.key を書き換えて変えられる
-- キーは横取りしないので、同じキーを使うほかのアプリの処理（AeroSpace の通知を閉じるなど）もそのまま動く
C.closeKey = C.closeKey or { mods = { "alt", "shift" }, key = "n" }
-- カードは group ごとに持ち、同じ group を出し直すと前のを消す
C.groups = C.groups or {}   -- group → { cards = { 画面ごとのカード }, timer = 消すタイマー, closable = 閉じるキーで閉じるか }
local groups = C.groups

local function isCloseKey(e)
  return e:getKeyCode() == hs.keycodes.map[C.closeKey.key] and e:getFlags():containExactly(C.closeKey.mods)
end

function C.close(group, fade)
  local g = groups[group]
  if not g then return end
  groups[group] = nil
  g.timer:stop()
  for _, k in ipairs(g.cards) do if fade then k.c:delete(fade) else k.c:delete() end end
  for _, other in pairs(groups) do if other.closable then return end end
  C.closeKeyWatcher:stop()
end

function C.onKey(e)
  if isCloseKey(e) then
    for name, g in pairs(groups) do if g.closable then C.close(name, 0.2) end end
  end
  return false
end
-- 閉じるキーで閉じるカードが出ている間だけ見張る。差し替えた後の関数を呼ぶよう、C.onKey を通して呼ぶ
C.closeKeyWatcher = C.closeKeyWatcher or hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e) return C.onKey(e) end)

-- 置き場所: 下の中央のカード（コピー表示）とそれより上に出すカードが同じ画面で重なるときは、上のカードを下のカードの上へずらす
-- （小さい画面で大きなコピー表示が出ると、画面の 6 割の高さに出すお知らせと重なるため）
local function layout()
  local bottomTop = {}   -- 画面ごとの、下の中央のカードの上端
  for _, g in pairs(groups) do
    for _, k in ipairs(g.cards) do if k.at == "bottom" then bottomTop[k.screen] = k.y + k.M end end
  end
  for _, g in pairs(groups) do
    for _, k in ipairs(g.cards) do
      local top = bottomTop[k.screen]
      if k.at ~= "bottom" and top and k.y + k.M + k.H > top - 12 then
        k.c:topLeft({ x = k.x, y = math.max(k.f.y - k.M, top - 12 - k.H - k.M) })
      end
    end
  end
end

-- 全部のモニタに 1 枚ずつカードを出し、出した canvas の並びを返す。o は次の表:
--   group, W と H（カードの大きさ）, M（影を描くためにカードの周りに空ける余白）,
--   at（置き場所: "bottom" は下の中央、数は画面の高さに対するカードの上端の位置、{ top = n } は画面の上端から n）,
--   elements（canvas の中身。座標は余白 M を含めた canvas の中での位置）, secs（出しておく秒数）, fadeIn, fadeOut,
--   closable（閉じるキーで閉じるか）, mouseCallback（無ければクリックで閉じる）
function C.show(o)
  C.close(o.group)
  local M, W, H = o.M, o.W, o.H
  local g = { cards = {}, closable = o.closable }
  groups[o.group] = g
  -- 途中でエラーになっても消えるよう、描く前に消すタイマーを仕掛ける（g に持っておかないと片付けられて消えなくなることがある）
  g.timer = hs.timer.doAfter(o.secs, function() if groups[o.group] == g then C.close(o.group, o.fadeOut) end end)
  for _, s in ipairs(hs.screen.allScreens()) do
    local f = s:frame()
    local y = o.at == "bottom" and (f.y + f.h - H - 60) or type(o.at) == "table" and (f.y + o.at.top) or (f.y + f.h * o.at)
    local k = { screen = s:id(), f = f, at = o.at, x = f.x + (f.w - W) / 2 - M, y = y - M, M = M, H = H }
    k.c = hs.canvas.new({ x = k.x, y = k.y, w = W + 2 * M, h = H + 2 * M })
    k.c:level(hs.canvas.windowLevels.overlay)
    k.c:behavior({ "canJoinAllSpaces", "stationary" })
    k.c:appendElements(table.unpack(o.elements))
    if o.mouseCallback then
      k.c:mouseCallback(o.mouseCallback)
    else
      k.c:canvasMouseEvents(true, false)
      k.c:mouseCallback(function() C.close(o.group, 0.2) end)
    end
    table.insert(g.cards, k)
  end
  layout()
  local shown = {}
  for _, k in ipairs(g.cards) do k.c:show(o.fadeIn); table.insert(shown, k.c) end
  if o.closable then C.closeKeyWatcher:start() end
  return shown
end

package.loaded["aro.cards"] = C
return C
