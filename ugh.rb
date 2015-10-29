require 'bundler/setup'
require 'sexpistol'
require 'pry'

def rest(expression)
  copy = expression.dup
  copy.shift
  copy
end

module Ugh

  class Arg
    def initialize(expr)
      @expr = expr
    end

    def to_bash
      @expr
    end
  end

  class Interpreter
    def transpile(program)
      expressions = Sexpistol.new.parse_string(program)
      result = []
      expressions.each do |expression|
        bash = expression_to_bash(expression)
        result << bash
      end
      return result.join("\n")+"\n"
    end

    # this might come in handy
    def all_bash_commands
      `echo -n $PATH | xargs -d : -I {} find {} -maxdepth 1 -executable -type f -printf '%P\n' | sort -u`.split.map(&:to_sym)
    end

    def expression_to_bash(expression)
      return expression if expression.is_a?(Integer)
      return expression if expression.is_a?(String)
      return expression.to_bash if expression.is_a?(Arg)

      if expression[0] == :def
        "#{expression[1]}=#{expression_to_bash(expression[2])}"
      elsif expression[0] == :backticks
        result = rest(expression).map do |expression|
          expression_to_bash(expression)
        end.join(' ')
        # backticks are tough to escape
        str = "\`#{result}"
        str = str+"\`"
        str
      elsif expression[0] == :bash
        rest(expression).map do |expression|
          expression
        end.join(' ')
      elsif expression[0] == :str
        chunks = rest(expression)
        result = chunks.inject do |memo, word|
          "#{memo}#{expression_to_bash(word)}"
        end
        result.to_s
      elsif expression[0] == :echo
        "echo #{expression_to_bash(expression[1])}"
      elsif expression[0] == :dollar
        "$#{expression[1]}"
      elsif expression[0] == :begin
        expressions = rest(expression)
        expressions.map do |expression|
          "#{expression_to_bash(expression)}"
        end.join("\n")
      elsif expression[0] == :invoke
        if expression.length == 3
          expression.shift
          function_name = expression.shift
          args = expression
          "#{function_name} #{args.join(' ')}"
        elsif expression.length == 2
          function_name = expression[1]
          "#{function_name}"
        end
      elsif expression[0] == :add
        "$((#{expression_to_bash(expression[1])} + #{expression_to_bash(expression[2])}))"
      elsif expression[0] == :function
        function_name = expression[1]
        if expression.length == 4
          # arguments are provided
          raw_args = expression[2]
          args = raw_args.each_with_index.map do |arg, index|
            "#{arg}=$#{index+1}"
          end.join('; ')
          expr = expression.last.map do |element|
            if raw_args.include?(element)
              "$#{element.to_s}"
            else
              element
            end
          end
<<-FUNCTION_WITH_ARGS
#{function_name} () {
  #{args}
  #{expression_to_bash(expr)}
}
FUNCTION_WITH_ARGS
        elsif expression.length == 3
        # no arguments
<<-FUNCTION_WITHOUT_ARGS
#{function_name} () {
  #{expression_to_bash(expression.last)}
}
FUNCTION_WITHOUT_ARGS
        end
      end
    end

  end
end
