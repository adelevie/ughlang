require 'bundler/setup'
require 'sexpistol'

def rest(expression)
  copy = expression.dup
  copy.shift
  copy
end

module Ugh
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
      if expression[0] == :define
        @table[expression[1]] = expression[2]
        "#{expression[1]}=#{expression[2]}"
      elsif expression[0] == :echo
        "echo #{expression_to_bash(expression[1])}"
      elsif expression[0] == :dollar
        "$#{expression[1]}"
      elsif expression[0] == :add
        "$((#{expression_to_bash(expression[1])} + #{expression_to_bash(expression[2])}))"
      elsif expression[0] == :function
        function_name = expression[1]
        if expression[2].is_a?(Array)
          # function with arguments
<<-FUNCTION_WITH_ARGS
#{function_name} () {
  # args go here
  #{expression[3]}
}
FUNCTION_WITH_ARGS
        else
          # function without arguments
<<-FUNCTION_WITHOUT_ARGS
#{function_name} () {
  # no args to declare
  #{expression_to_bash(expression[2])}
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
