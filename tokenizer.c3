module tokenizer;

const ushort MAX_TOKENS = 4096; 
ushort[MAX_TOKENS] token_output;

/**
 * Safely compares two text strings in memory.
 */
fn bool strings_match(char* a, char* b, int len)
{
    for (int i = 0; i < len; i++)
    {
        if (a[i] != b[i]) { return false; }
    }
    return true;
}

/**
 * High-performance universal tokenizer for LLM prompts and source code.
 */
fn int tokenize_input_text(char* text_ptr, int text_len) @wasm("tokenize_input_text")
{
    if (text_len <= 0 || text_len > MAX_TOKENS) return 0;

    int token_count = 0;
    int i = 0;

    while (i < text_len)
    {
        char current_char = text_ptr[i];

        // 1. INDENTATION AND REPEATED SPACES
        if (current_char == ' ')
        {
            int space_run = 1;
            while (i + space_run < text_len && text_ptr[i + space_run] == ' ' && space_run < 8)
            {
                space_run++;
            }
            if (space_run >= 2)
            {
                token_output[token_count] = (ushort)(3000 + space_run);
                token_count++;
                i += space_run;
                if (token_count >= MAX_TOKENS) break;
                continue;
            }
        }

        // 2. EXTENDED PROGRAMMING KEYWORDS
        if ((current_char >= 'a' && current_char <= 'z') || 
            (current_char >= 'A' && current_char <= 'Z') || 
            current_char == '_')
        {
            int word_len = 1;
            while (i + word_len < text_len)
            {
                char next_c = text_ptr[i + word_len];
                if ((next_c >= 'a' && next_c <= 'z') || 
                    (next_c >= 'A' && next_c <= 'Z') || 
                    (next_c >= '0' && next_c <= '9') || 
                    next_c == '_')
                {
                    word_len++;
                }
                else
                {
                    break;
                }
            }

            char* word_start = &text_ptr[i];
            ushort matched_token = 0;

            if (word_len == 5 && strings_match(word_start, "const", 5)) { matched_token = 5001; }
            else if (word_len == 6 && strings_match(word_start, "return", 6)) { matched_token = 5002; }
            else if (word_len == 8 && strings_match(word_start, "function", 8)) { matched_token = 5003; }
            else if (word_len == 2 && strings_match(word_start, "if", 2)) { matched_token = 5004; }
            else if (word_len == 4 && strings_match(word_start, "else", 4)) { matched_token = 5005; }
            else if (word_len == 3 && strings_match(word_start, "let", 3)) { matched_token = 5006; }
            else if (word_len == 4 && strings_match(word_start, "void", 4)) { matched_token = 5007; }
            else if (word_len == 5 && strings_match(word_start, "while", 5)) { matched_token = 5008; }
            else if (word_len == 6 && strings_match(word_start, "import", 6)) { matched_token = 5009; }
            else if (word_len == 6 && strings_match(word_start, "export", 6)) { matched_token = 5010; }
            // ADDITIONAL COMPILED KEYWORDS
            else if (word_len == 5 && strings_match(word_start, "async", 5)) { matched_token = 5011; }
            else if (word_len == 5 && strings_match(word_start, "await", 5)) { matched_token = 5012; }
            else if (word_len == 5 && strings_match(word_start, "class", 5)) { matched_token = 5013; }
            else if (word_len == 2 && strings_match(word_start, "fn", 2)) { matched_token = 5014; }
            else if (word_len == 6 && strings_match(word_start, "module", 6)) { matched_token = 5015; }

            if (matched_token != 0)
            {
                token_output[token_count] = matched_token;
                token_count++;
                i += word_len;
                if (token_count >= MAX_TOKENS) break;
                continue;
            }
        }

        // 3. COMMON PROGRAMMING OPERATORS AND SYMBOLS (3 and 2 characters)
        if (i + 2 < text_len)
        {
            char c1 = text_ptr[i];
            char c2 = text_ptr[i + 1];
            char c3 = text_ptr[i + 2];

            if (c1 == '=' && c2 == '=' && c3 == '=') { token_output[token_count] = 4001; i += 3; token_count++; continue; } 
            if (c1 == '!' && c2 == '=' && c3 == '=') { token_output[token_count] = 4002; i += 3; token_count++; continue; } 
            if (c1 == '.' && c2 == '.' && c3 == '.') { token_output[token_count] = 4003; i += 3; token_count++; continue; } 
        }

        if (i + 1 < text_len)
        {
            char c1 = text_ptr[i];
            char c2 = text_ptr[i + 1];

            if (c1 == '=' && c2 == '>') { token_output[token_count] = 4101; i += 2; token_count++; continue; } 
            if (c1 == '&' && c2 == '&') { token_output[token_count] = 4102; i += 2; token_count++; continue; } 
            if (c1 == '|' && c2 == '|') { token_output[token_count] = 4103; i += 2; token_count++; continue; } 
            if (c1 == '+' && c2 == '=') { token_output[token_count] = 4104; i += 2; token_count++; continue; } 
            if (c1 == '-' && c2 == '=') { token_output[token_count] = 4105; i += 2; token_count++; continue; } 
            if (c1 == '=' && c2 == '=') { token_output[token_count] = 4106; i += 2; token_count++; continue; } 
            if (c1 == '!' && c2 == '=') { token_output[token_count] = 4107; i += 2; token_count++; continue; } 
            if (c1 == '<' && c2 == '=') { token_output[token_count] = 4108; i += 2; token_count++; continue; } 
            if (c1 == '>' && c2 == '=') { token_output[token_count] = 4109; i += 2; token_count++; continue; } 
            if (c1 == '/' && c2 == '/') { token_output[token_count] = 4110; i += 2; token_count++; continue; } 
        }

        // 4. UTF-8 MULTIBYTE SEQUENCES (Accents, Enye, Emojis)
        if ((current_char & 0x80) != 0) 
        {
            int utf8_len = 1;
            if ((current_char & 0xE0) == 0xC0) { utf8_len = 2; }      
            else if ((current_char & 0xF0) == 0xE0) { utf8_len = 3; } 
            else if ((current_char & 0xF8) == 0xF0) { utf8_len = 4; } 

            if (i + utf8_len <= text_len) 
            {
                token_output[token_count] = (ushort)(20000 + (current_char & 0x1F)); 
                token_count++;
                i += utf8_len;
                if (token_count >= MAX_TOKENS) break;
                continue;
            }
        }

        // 5. COMMON CHARACTER PAIRS (Residual plain-text mapping)
        if (i + 1 < text_len)
        {
            char c1 = text_ptr[i];
            char c2 = text_ptr[i + 1];

            if (c1 == 'e' && c2 == 'n') { token_output[token_count] = 101; i += 2; token_count++; continue; }
            if (c1 == 'd' && c2 == 'e') { token_output[token_count] = 102; i += 2; token_count++; continue; }
            if (c1 == 'l' && c2 == 'a') { token_output[token_count] = 103; i += 2; token_count++; continue; }
            if (c1 == 'e' && c2 == 's') { token_output[token_count] = 104; i += 2; token_count++; continue; }
        }

        // 6. SINGLE-CHARACTER FALLBACK
        token_output[token_count] = (ushort)current_char;
        token_count++;
        i++;
        
        if (token_count >= MAX_TOKENS) break;
    }
  
    return token_count;
}

fn ushort* get_token_output_pointer() @wasm("get_token_output_pointer")
{
    return &token_output;
}
