require 'bundler/setup'
require 'sexpistol'
require 'pry'
require 'tilt'
require 'erb'

def rest(expression)
  copy = expression.dup
  copy.shift
  copy
end

module Ugh

  class BashLiteral
    def initialize(expr)
      @expr = expr
    end

    def to_bash
      @expr.to_s
    end
  end

  module Util
    def self.parse_string(program)
      Sexpistol.new.parse_string(program)
    end

    def self.dashes_to_underscore(sym)
      sym.to_s.gsub('-', '_')
    end

    def self.quote_string(str)
      "\"#{str}\""
    end

    def self.rest(arr)
      dup = arr.dup
      dup.shift
      dup
    end

    def self.random_string
      (0...20).map { (65 + rand(26)).chr }.join
    end

    def self.function_name
      @counter ||= 0
      @counter = @counter + 1
      "function_#{@counter.to_s}"
    end
  end

  module StdLib
    def self.echo(expr)
      "echo #{expr}"
    end

    def self.def(key, value)
      "#{key}=#{value}"
    end

    def self.dollar(variable)
      "$#{variable}".gsub(/"/, '')
    end

    def self.eval(expr)
      "\`#{expr}\`"
    end

    def self.apply(function_name, expressions)
      "#{function_name} #{expressions.join(' ')}"
    end

    def self.pipe(expressions)
      expressions.join(' | ')
    end

    def self.defn(function_name, function_args, function_body)
      template = Tilt::ERBTemplate.new('templates/defn.erb', trim: '-')
      ctx = self
      str = template.render(self, {
        function_name: function_name,
        function_args: function_args,
        function_body: function_body
      })
      str
    end

    def self.local(key, value)
      "local #{StdLib::def(key, value)}"
    end

    def self.make_conditional(operator)
      Proc.new do |left, right|
        "[ #{left} #{operator} #{right} ]"
      end
    end

    def self.eq(left, right)
      make_conditional("-eq").call(left, right)
    end

    def self.ne(left, right)
      make_conditional("-ne").call(left, right)
    end

    def self.gt(left, right)
      make_conditional("-gt").call(left, right)
    end

    def self.ge(left, right)
      make_conditional("-ge").call(left, right)
    end

    def self.le(left, right)
      make_conditional("-eq").call(left, right)
    end

    def self.if(condition, true_block, false_block)
      template = Tilt::ERBTemplate.new('templates/if.erb', trim: '-')
      ctx = self
      str = template.render(self, {
        condition: condition,
        true_block: true_block,
        false_block: false_block
      })
      str
    end

    def self.deflist(list_name, items)
      "#{list_name}=(#{items})"
    end

    def self.get(list_name, index)
      "${#{list_name}[#{index}]}"
    end

    def self.set(list_name, index, value)
      "#{list_name}[#{index}]=#{value}"
    end

    def self.length(list_name)
      "${##{list_name}[@]}"
    end

    def self.append(list_name, items)
      "#{list_name}=(\"${#{list_name}[@]}\" #{items.join(' ')})"
    end

    def self.each(items, function_name, function_args, function_body)
      function = StdLib::defn(function_name, function_args, function_body)
      str = <<-END.gsub(/^ {6}/, '')
      for i in #{items}; do
        #{function_name} $i
      done
      END
      [function, str.rstrip].join("\n")
    end

    def self.str(items)
      items
    end

    def self._do(expressions)
      template = Tilt::ERBTemplate.new('templates/do.erb', trim: '-')
      ctx = self
      str = template.render(self, {
        expressions: expressions
      })
    end
  end

  class Interpreter
    def transpile(program)
      expressions = Util::parse_string(program)
      result = []
      result << "#!/bin/bash"
      result << ""
      expressions.each do |expression|
        bash = expression_to_bash(expression)
        result << bash
      end
      return result.join("\n")+"\n"
    end

    def expression_to_bash(expression)
      return Util::quote_string(expression) if expression.is_a?(String)
      return expression.to_bash if expression.is_a?(BashLiteral)
      return expression.to_s if expression.is_a?(Symbol)
      return expression if expression.is_a?(Integer)

      case expression[0]
      when :echo
        expr = expression_to_bash(expression[1])
        StdLib::echo(expr)
      when :def
        key = Util::dashes_to_underscore(expression[1])
        value = expression_to_bash(expression[2])
        StdLib::def(key, value)
      when :dollar
        variable = expression_to_bash(
          BashLiteral.new(
            Util::dashes_to_underscore(expression_to_bash(expression[1]))
          )
        )
        StdLib::dollar(variable)
      when :eval
        expr = expression_to_bash(expression[1])
        StdLib::eval(expr)
      when :apply
        function_name = Util::dashes_to_underscore(expression[1])
        expression.shift
        expression.shift
        expressions = expression.map {|expr| expression_to_bash(expr)}
        StdLib::apply(function_name, expressions)
      when :pipe
        expressions = Util::rest(expression).map do |expr|
          expression_to_bash(expr)
        end
        StdLib::pipe(expressions)
      when :defn
        # arguments are *not* defined in function
        if expression.length == 3
          function_name = Util::dashes_to_underscore(expression[1])
          function_args = []
          function_body = expression_to_bash(expression[2])
          StdLib::defn(function_name, function_args, function_body)
        # arguments are defined in function
        elsif expression.length == 4
          function_name = Util::dashes_to_underscore(expression[1])
          function_args = expression[2]
          function_body = expression_to_bash(expression[3])
          StdLib::defn(function_name, function_args, function_body)
        end
      when :do
        expressions = rest(expression)
        expressions.map! {|expr| expression_to_bash(expr)}
        StdLib::_do(expressions)
      when :local
        key = Util::dashes_to_underscore(expression[1])
        value = expression_to_bash(expression[2])
        StdLib::local(key, value)
      when :eq
        left = Util::quote_string(expression_to_bash(expression[1]))
        right = Util::quote_string(expression_to_bash(expression[2]))
        StdLib::eq(left, right)
      when :ne
        left = Util::quote_string(expression_to_bash(expression[1]))
        right = Util::quote_string(expression_to_bash(expression[2]))
        StdLib::ne(left, right)
      when :gt
        left = Util::quote_string(expression_to_bash(expression[1]))
        right = Util::quote_string(expression_to_bash(expression[2]))
        StdLib::gt(left, right)
      when :lt
        left = Util::quote_string(expression_to_bash(expression[1]))
        right = Util::quote_string(expression_to_bash(expression[2]))
        StdLib::lt(left, right)
      when :le
        left = Util::quote_string(expression_to_bash(expression[1]))
        right = Util::quote_string(expression_to_bash(expression[2]))
        StdLib::le(left, right)
      when :if
        condition = expression_to_bash(expression[1])
        true_block = expression_to_bash(expression[2])
        false_block = nil
        if expression[3]
          false_block = expression_to_bash(expression[3])
        end
        StdLib::if(condition, true_block, false_block).rstrip
      when :deflist
        list_name = Util::dashes_to_underscore(expression[1])
        expression.shift
        expression.shift
        items = expression_to_bash(expression)
        StdLib::deflist(list_name, items)
      when :get
        list_name = Util::dashes_to_underscore(expression[1])
        index = expression_to_bash(expression[2])
        StdLib::get(list_name, index)
      when :set
        list_name = Util::dashes_to_underscore(expression[1])
        index = expression_to_bash(expression[2])
        value = expression_to_bash(expression[3])
        StdLib::set(list_name, index, value)
      when :inspect
        list_name = Util::dashes_to_underscore(expression[1])
        StdLib::get(list_name, "@")
      when :length
        list_name = Util::dashes_to_underscore(expression[1])
        StdLib::length(list_name)
      when :append
        list_name = Util::dashes_to_underscore(expression[1])
        expression.shift # remove :append
        expression.shift # remove list name
        items = expression.map {|expr| expression_to_bash(expr)}
        StdLib::append(list_name, items)
      when :lambda
        function_name = Util::function_name
        function_args = expression[1]
        function_body = expression_to_bash(expression[2])
        StdLib::defn(function_name, function_args, function_body).rstrip
      when :each
        items = expression_to_bash(expression[1])
        function = expression[2]
        function_name = Util::function_name
        function_args = function[1]
        function_body = expression_to_bash(function[2])
        StdLib::each(items, function_name, function_args, function_body).rstrip
      when :str
        chunks = rest(expression)
        chunks.map! {|expr| expression_to_bash(expr)}
        chunks.join
      else
        expressions = expression.map {|expr| expression_to_bash(expr)}
        expressions.join(' ')
      end
    end

  end
end
