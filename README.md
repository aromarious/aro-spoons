# aro-spoons

[Hammerspoon](https://www.hammerspoon.org/) の Spoon をいくつか置いています。どの Spoon も、画面の上に自前のカードを出して知らせます。macOS の通知ではないので、集中モードの間も表示されます。

| Spoon | すること |
|---|---|
| AroCopyCard | コピーしたときに、全部のモニタの下の中央へ、コピーした中身を少しの間見せる |

## 入れ方

### zip から入れる

`Spoons/` にある zip（例 `AroCopyCard.spoon.zip`）をダウンロードして展開し、できた `AroCopyCard.spoon` をダブルクリックします。Hammerspoon が `~/.hammerspoon/Spoons/` に入れます。

そのあと `~/.hammerspoon/init.lua` に次を書きます。

```lua
hs.loadSpoon("AroCopyCard")
spoon.AroCopyCard:start()
```

### SpoonInstall で入れる

[SpoonInstall](https://www.hammerspoon.org/Spoons/SpoonInstall.html) を使っているなら、このリポジトリを登録すると、更新も SpoonInstall に任せられます。このリポジトリのブランチは `main` なので、`branch = "main"` を付けてください。

```lua
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall.repos.aro = {
  url = "https://github.com/aromarious/aro-spoons",
  desc = "aro-spoons",
  branch = "main",
}
spoon.SpoonInstall:andUse("AroCopyCard", { repo = "aro", start = true })
```

## AroCopyCard

コピーすると、コピーした中身を見せるカードを画面の下の中央に 2 秒出します。音は鳴らず、画面も光りません。

文字はそのまま出します。書式付きの文字（Web ページや Word からのコピー）は、太字・色・リンクなどの書式を残して出します。文字の色は、ライトモードでもダークモードでも読めるように直します。画像は縮小して出します。長い中身は先頭だけ出します。

1Password・パスワード（Apple）・Bitwarden からのコピーは、パスワードを画面に出さないように中身を伏せます。

出ているカードは、alt-shift-n で消せます。このキーは横取りしないので、同じキーを使うほかのアプリの操作もそのまま動きます。

### 設定

`start()` の前に書きます。

```lua
hs.loadSpoon("AroCopyCard")
spoon.AroCopyCard.secs = 3                                        -- カードを出しておく秒数（既定 2）
spoon.AroCopyCard.fontSize = 20                                   -- 文字の大きさ（既定 24）
spoon.AroCopyCard.label = "Copied"                                -- カードの左上の見出し（既定「コピー」）
spoon.AroCopyCard.closeKey = { mods = { "ctrl", "alt" }, key = "x" }   -- カードを閉じるキー（既定 alt-shift-n）
spoon.AroCopyCard.secretApps["com.example.vault"] = true          -- 中身を伏せるアプリを足す（bundle ID）
spoon.AroCopyCard:start()
```

ほかに、1 行の文字数の目安 `width`（既定 40）、出す文字数の上限 `maxChars`（既定 800）、出す行数の上限 `maxLines`（既定 12）を変えられます。

### iPhone からコピーした写真

ユニバーサルクリップボードで iPhone からコピーした写真は、画像のデータではなく、一時ファイルの場所として Mac に届きます。そのファイルは、Hammerspoon にフルディスクアクセスを許可していないと読めません。許可していないときは、カードに写真のファイル名を出します。

## Aro の Spoon を 2 つ以上入れたとき

カードを画面に出す部分（`cards.lua`）は、どの Spoon にも同じものが入っています。2 つ以上入れても、実際に動くのは一番新しい版の 1 つだけです。そのため、カードどうしが重ならず、閉じるキーも 1 回の操作で全部のカードに効きます。閉じるキーの設定は全部の Spoon で共通で、最後に `start()` した Spoon の設定になります。

## 作る人向け

`lib/cards.lua` がカードを画面に出す部分の元です。`make` で各 Spoon に写し、`make release` で `Spoons/` に zip と `docs/docs.json` を作ります。

`cards.lua` の版（ファイル先頭の `VERSION`）を上げるときも、古い Spoon が呼ぶ関数の名前と引数は変えません（足すのはかまいません）。

## ライセンス

MIT
