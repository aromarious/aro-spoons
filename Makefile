# カードを表示する部分（lib/cards.lua）を各 Spoon に写し、Spoons/ に zip を作る
SPOONS := $(wildcard Source/*.spoon)

all: $(SPOONS:%=%/cards.lua)

Source/%.spoon/cards.lua: lib/cards.lua
	cp $< $@

release: all
	mkdir -p Spoons docs
	lua scripts/docs.lua $(SPOONS) > docs/docs.json
	for s in $(SPOONS); do n=$$(basename $$s); rm -f Spoons/$$n.zip; (cd Source && zip -qr ../Spoons/$$n.zip $$n -x '*.DS_Store'); done

.PHONY: all release
