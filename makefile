.PHONY: all clean

LUMEN := LUMEN_HOST=luajit lumen
MODS :=	bin/motor.lua		\
	bin/linux/system.lua	\
	bin/darwin/system.lua	\
	bin/buffer.lua		\
	bin/stream.lua		\
	bin/http.lua		\
	bin/pq.lua

all: $(MODS)

clean:
	@git checkout bin/*.lua
	@rm -f obj/*

bin/pq.lua: pq.l obj/lib.lua
	@echo $@
	@$(LUMEN) obj/lib.lua -c $< -o $@ -t lua

bin/motor.lua: motor.l obj/lib.lua
	@echo $@
	@$(LUMEN) obj/lib.lua -c $< -o $@ -t lua

bin/linux/%.lua : lib/linux/%.l obj/lib.lua
	@echo $@
	@$(LUMEN) obj/lib.lua -c $< -o $@ -t lua

bin/darwin/%.lua : lib/darwin/%.l obj/lib.lua
	@echo $@
	@$(LUMEN) obj/lib.lua -c $< -o $@ -t lua

obj/%.lua : %.l
	@echo "  $@"
	@$(LUMEN) -c $< -o $@ -t lua

bin/%.lua : %.l
	@echo $@
	@$(LUMEN) -c $< -o $@ -t lua
