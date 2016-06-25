module LFR
  require 'Parser'
  require 'readline'
  class Interpreter
    def initialize
      @environment = {:true=>true, :false=>false, :nil=>nil}
      dir=File.dirname(File.expand_path(__FILE__))
      run(File.read("#{dir}/basic_functions.lfr"))
      @quit = false
      @specials = [:define, :ruby, :if, :lambda, :defun, :defn, :fn,
                   :quote]
      comp = proc{ |s| (@environment.keys + @specials).
                   grep(/^#{Regexp.escape(s)}/)}
      Readline.completion_append_character = " "
      Readline.completion_proc = comp
    end
    def tokenize(string)
      Parser.tokenize(string)
    end
    def execute(tokens)
      result = nil
      Parser.tokens2exps(tokens).each do |exp|
        result = evaluate exp
      end
      result
    end
    def run(string)
      execute Parser.tokens2exps(Parser.tokenize string)
    end
    def evaluate(expr, environment = @environment)
      if (expr.is_a? Numeric) || (expr.is_a? String)
        return expr
      elsif expr[0] == :define
        _, name, rest = expr
        if name.is_a? Array
          name, *var = name
          rest = [:define, name, [:lambda, var, rest]]
        end
        environment[name] = evaluate rest, environment
        return environment[name]
      elsif expr[0] == :defun || expr[0] == :defn
        _, name, var, expr = expr
        evaluate([:define, name, [:lambda, var, expr]], environment)
      elsif expr[0] == :quote
        expr[1]
      elsif expr[0] == :if
        _, test, opt1, opt2 = expr
        exp = evaluate(test, environment) ? opt1 : opt2
        evaluate(exp, environment)
      elsif expr[0] == :ruby
        _, code = expr
        eval("lambda{#{code}}")
      elsif expr[0] == :lambda || expr[0] == :fn
        _, var, expr = expr
        lambda { |*args| evaluate(expr,
                                  environment.merge(Hash[var.zip(args)])) }
      elsif expr.is_a? Array
        fn, *rest = expr
        rest = rest.collect{|x| evaluate(x, environment)}
        fn = environment[fn] if fn.is_a? Symbol
        fn = evaluate(fn, environment) if fn.is_a? Array
        return fn.call *rest
      elsif expr.is_a? Symbol
        environment[expr]
      end
    end
    def repl(prompt = '> ')
      while !@quit
        line = ""
        input = nil
        currentPrompt = prompt
        tokens = nil
        begin
          line += " " if line != ""
          input = Readline::readline(currentPrompt)
          line += input.to_s
          Readline::HISTORY.push(line)
          currentPrompt = "... "
          tokens = tokenize(line)
        end until tokens.count(:rp) >= tokens.count(:lp)
        begin
          result = execute(tokens)
          @quit = true if input.nil?
          if !@quit
            if result.nil? && input != ""
              print "nil"
            else
              print result
            end
          end
          print("\n")
        rescue Exception => e
          p e
        end
      end
    end
  end
end


