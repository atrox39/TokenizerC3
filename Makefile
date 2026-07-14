.PHONY: tokenizer.c3

tokenizer.c3:
	c3c compile --target wasm32 --no-entry --reloc=none -o tokenizer tokenizer.c3
