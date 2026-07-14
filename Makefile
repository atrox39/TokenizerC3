tokenizer.c3: tokenizer.wasm
	c3c compile --target wasm32 --no-entry --reloc=none -o tokenizer tokenizer.c3
