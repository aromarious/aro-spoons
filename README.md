# aro-spoons

自分用に作った [Hammerspoon](https://www.hammerspoon.org/) の Spoon を置いています。今あるのは AroCopyCard だけです。

## AroCopyCard

クリップボードを監視し、何かコピーされたらカードとして表示する Spoon です。

- クリップボード内容を全モニタの中央下部に 2 秒間表示
- macOS の通知は使っていないので、集中モード中でも表示
- カードの色はシステムテーマ（ライト／ダーク）に従う
- 書式つきの文字は書式つきのまま表示し、画像は小さくして表示
- 長いテキストは冒頭のみを表示
- 1Password などのパスワード管理アプリからのコピーは、コピー内容の代わりに「（中身は表示しません）」と表示
- 出ているカードはクリックか alt-shift-n で消せる

### インストール方法（手動）

1. ダウンロード: [Spoons/AroCopyCard.spoon.zip](Spoons/AroCopyCard.spoon.zip) をダウンロードして展開します。
2. ダブルクリック: できた `AroCopyCard.spoon` をダブルクリックすると、AroCopyCard が `~/.hammerspoon/Spoons/` にインストールされます。
3. 設定ファイルの記述: `~/.hammerspoon/init.lua` に次を書きます。

   ```lua
   hs.loadSpoon("AroCopyCard")
   spoon.AroCopyCard:start()
   ```

4. 再読み込み: メニューバーの Hammerspoon のアイコンから「Reload Config」を選ぶと、AroCopyCard が動き始めます。

### インストール方法（SpoonInstall）

1. SpoonInstall のインストール: [SpoonInstall](https://www.hammerspoon.org/Spoons/SpoonInstall.html) が入っていなければ、[SpoonInstall.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/SpoonInstall.spoon.zip) をダウンロードして展開し、ダブルクリックでインストールします。
2. 設定ファイルの記述: `~/.hammerspoon/init.lua` に次を書きます。

   ```lua
   hs.loadSpoon("SpoonInstall")
   spoon.SpoonInstall.repos.aro = {
     url = "https://github.com/aromarious/aro-spoons",
     desc = "aro-spoons",
     branch = "main",
   }
   spoon.SpoonInstall:andUse("AroCopyCard", { repo = "aro", start = true })
   ```

3. 再読み込み: メニューバーの Hammerspoon のアイコンから「Reload Config」を選ぶと、AroCopyCard がダウンロードされて動き始めます。

最新にするときは、Hammerspoon のコンソールで次を実行してから再読み込みします。

```lua
spoon.SpoonInstall:updateRepo("aro")
spoon.SpoonInstall:installSpoonFromRepo("AroCopyCard", "aro")
```

### 設定

`start()` の前に書きます。全項目省略可

```lua
spoon.AroCopyCard.secs = 3                                             -- 出しておく秒数（既定 2）
spoon.AroCopyCard.fontSize = 20                                        -- 文字の大きさ（既定 24）
spoon.AroCopyCard.label = "Copied"                                     -- 左上の見出し（既定「コピー」）
spoon.AroCopyCard.closeKey = { mods = { "ctrl", "alt" }, key = "x" }   -- 消すキー（既定 alt-shift-n）
spoon.AroCopyCard.secretApps["com.example.vault"] = true               -- 中身を伏せるアプリを足す（bundle ID）
```

`width`（1 行の文字数の目安、既定 40）、`maxChars`（既定 800）、`maxLines`（既定 12）も変えられます。

### iPhone の写真をコピーしたとき

ユニバーサルクリップボードで届く写真は、Mac 側では一時ファイルになっています。Hammerspoon にフルディスクアクセスを許可していればその写真を、していなければファイル名だけを出します。

## ライセンス

MIT
