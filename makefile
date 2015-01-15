.PHONY: all clean

LUMEN := LUMEN_HOST=luajit lumen
RUNTIME := lib/lumen/runtime.lua lib/lumen/io.lua
LIBS :=	obj/motor.lua

all: bin/echo.lua

clean:
	@git checkout bin/echo.lua
	@rm -f obj/*

bin/echo.lua: $(LIBS) obj/echo.lua
	@echo $@
	@cat $(RUNTIME) $^ > $@.tmp
	@mv $@.tmp $@

obj/%.lua : %.l
	@echo "  $@"
	@$(LUMEN) -c $< -o $@ -t lua
