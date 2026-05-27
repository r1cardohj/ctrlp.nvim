.PHONY: test clean

test:
	@nvim --headless -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }" \
		-c "qa!"

clean:
	@rm -rf tests/deps
