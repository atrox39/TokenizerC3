# C3 WASM Prompt Budget Optimizer

This project is a small browser demo that compiles a C3 tokenizer to WebAssembly and uses it from a plain HTML page.

The app analyzes source code or prompt text, estimates token-based model cost, and trims the output to fit a budget. When the budget is exceeded, it tries to cut at safer syntax boundaries such as `}` or `;`.

## Files

- `tokenizer.c3`: C3 source for the tokenizer and the exported WASM functions.
- `index.html`: Browser UI that loads `tokenizer.wasm`, visualizes tokens, and applies the budget cutoff logic.
- `Makefile`: Minimal build rule for generating the WebAssembly binary.

## How It Works

The tokenizer applies a few lightweight heuristics:

- Collapses repeated spaces into compact token IDs.
- Detects common programming keywords such as `const`, `return`, `async`, `fn`, and `module`.
- Recognizes multi-character operators like `===`, `!==`, `=>`, `&&`, and `//`.
- Handles UTF-8 multibyte sequences.
- Falls back to plain character and character-pair token mapping when no special rule matches.

On the frontend:

- The input text is encoded with `TextEncoder`.
- The bytes are copied into WASM memory.
- The exported C3 tokenizer returns token IDs.
- JavaScript reconstructs token strings for visualization.
- The UI estimates model cost and computes the maximum allowed token count for the selected budget.
- If the input exceeds the budget, the app searches backward for `}` or `;` before applying the final cutoff.

## Exported WASM Functions

The C3 module exposes these functions to JavaScript:

- `tokenize_input_text`
- `get_token_output_pointer`

## Build

Requirements:

- `c3c` available in your `PATH`
- `make` or a compatible tool that can run the rule in `Makefile`

Build the WebAssembly file:

```bash
make tokenizer.wasm
```

Equivalent direct command:

```bash
c3c compile --target wasm32 --no-entry --reloc=none -o tokenizer tokenizer.c3
```

## Run Locally

Because the page fetches `tokenizer.wasm`, serve the folder through a local HTTP server instead of opening `index.html` directly from `file://`.

Example using Python:

```bash
python -m http.server 8080
```

Then open:

- `http://localhost:8080/index.html`

## Demo Flow

1. Enter source code or prompt text.
2. Select a target model and maximum budget.
3. Click `Analyze with C3`.
4. Review total tokens, estimated cost, and final preserved tokens.
5. Copy the optimized output if needed.

## Notes

- Token counts are heuristic and intended for visualization and budget trimming, not as a replacement for provider-specific tokenizers.
- The syntax-safe cutoff currently prefers `}` and `;`, which works best for code-like input.
