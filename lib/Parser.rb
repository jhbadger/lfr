module LFR
  class Parser
    def Parser.tokenize(string)
      pos = 0
      tokens = []
      while pos < string.length
        if string[pos] == "(" || string[pos] == "["
          tokens.push :lp
          pos += 1
        elsif string[pos] == ")" || string[pos] == "]"
          tokens.push :rp
          pos += 1
        elsif string[pos] =~/[0-9|\-]/
          token = ""
          while string[pos] =~/[0-9]|\.|[e|E]|\+|\-/
            token += string[pos]
            pos += 1
          end
          if token.index(/\.|e|E/)
            tokens.push token.to_f
          else
            tokens.push(token.to_i)
          end
        elsif string[pos] == '"'
          token = ""
          pos += 1
          while string[pos] != '"' && pos < string.length
            token += string[pos]
            pos += 1
          end
          tokens.push token
          pos += 1
        elsif string[pos] == ';'
          while string[pos] != '\n' && pos < string.length
            pos += 1
          end
          pos += 1
        elsif string[pos] == "'"
          tokens.push :q
          pos += 1
        elsif string[pos] =~/\s|,/
          pos += 1
        else
          token = ""
          while string[pos] !~/\s|\)|\(|\[|\]/ && pos < string.length
            token += string[pos]
            pos += 1
          end
          tokens.push token.to_sym
        end
      end
      tokens
    end
    def Parser.tokens2exps(tokens, idx = 0)
      parsed = []
      quoted = false
      while idx < tokens.length
        token = tokens[idx]
        if token == :lp
          token, idx = tokens2exps(tokens, idx + 1)
        elsif token == :rp
          return [parsed, idx]
        elsif token == :q
          quoted = true
          idx += 1
          next
        end
        if quoted
          parsed.push [:quote, token]
          quoted = false
        else
          parsed.push token
        end
        idx += 1
      end
      parsed
    end
  end
end

