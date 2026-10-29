# カードを表示する部分（lib/cards.lua）を各 Spoon に写し、Spoons/ に zip を作る
# make release: Spoons/ の zip と docs/docs.json を作り直す。Spoon の中身を変えたら、その Spoon の obj.version を上げてから（SpoonInstall で入れた人はこの版で新しい版かを判断する）
SPOONS := $(wildcard Source/*.spoon)

all: $(SPOONS:%=%/cards.lua)

Source/%.spoon/cards.lua: lib/cards.lua
	cp $< $@

release: all
	mkdir -p Spoons docs
	lua scripts/docs.lua $(SPOONS) > docs/docs.json
	for s in $(SPOONS); do n=$$(basename $$s); rm -f Spoons/$$n.zip; (cd Source && zip -qr ../Spoons/$$n.zip $$n -x '*.DS_Store'); done

.PHONY: all release
