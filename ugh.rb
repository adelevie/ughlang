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
  class Environment

    attr_accessor :parent

    def initialize(parent = nil)
      @parent = parent
      @table = {}
    end

    def find(name)
      return @table[name] if @table.has_key?(name)
      return nil if @parent.nil?
      return @parent.find(name)
    end

    def define(name, value)
      @table[name] = value
    end
  end

  class Interpreter
    attr_accessor :base_environment,
                  :current_environment

    def initialize
      @base_environment = @current_environment = Ugh::Environment.new
      @table = {}
    end

    def transpile(program)
      expressions = Sexpistol.new.parse_string(program)
      result = []
      expressions.each do |expression|
        bash = expression_to_bash(expression)
        result << bash
      end
      return result.join("\n")+"\n"
    end

    def expression_to_bash(expression)
      return expression if expression.is_a?(Integer)
      return expression if expression.is_a?(String)
      return expression.to_bash if expression.is_a?(Arg)

      if expression[0] == :define
        @table[expression[1]] = expression[2]
        "#{expression[1]}=#{expression[2]}"
      elsif expression[0] == :echo
        "echo #{expression_to_bash(expression[1])}"
      elsif expression[0] == :dollar
        "$#{expression[1]}"
      elsif expression[0] == :invoke
        function_call = expression[1]
        function_name = function_call[0]
        args = rest(function_call)
        "#{function_name} #{args.join(' ')}"
      elsif expression[0] == :add
        "$((#{expression_to_bash(expression[1])} + #{expression_to_bash(expression[2])}))"
      elsif expression[0] == :function
        function_name = expression[1]
        if expression.length == 4
          # arguments are provided
          raw_args = expression[2]
          args = raw_args.each_with_index.map do |arg, index|
            "#{arg}=$#{index+1}"
          end.join("/n")
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

    def run(program)
      expressions = Sexpistol.new.parse_string(program)
      result = nil
      expressions.each do |expression|
        result = evaluate(expression)
      end
      return result
    end

    def evaluate(expression)
      return @current_environment.find(expression) if expression.is_a?(Symbol)
      return expression unless expression.is_a?(Array)

      if expression[0] == :define
        return @current_environment.define(expression[1], evaluate(expression[2]))

      elsif expression[0] == :native_function
        return eval(expression[1])

      else # function call
        function = evaluate(expression[0])
        arguments = expression.slice(1, expression.length)
        return function.call(arguments, self)
      end
    end

  end
end
