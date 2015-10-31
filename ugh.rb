require 'bundler/setup'
require 'sexpistol'
require 'pry'

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
  end

  module StdLib
    def self.echo(expr)
      "echo #{expr}"
    end

    def self.def(key, value)
      "#{key}=#{value}"
    end

    def self.dollar(variable)
      "$#{variable}"
    end

    def self.eval(expr)
      "\`#{expr}\`"
    end

    def self.defn(function_name, function_args, function_body)
      str = nil
      if function_args.length > 0
        str = <<-END.gsub(/^ {8}/, '')
        #{function_name} () {
          #{function_args.map {|a| "  local #{a}=$1; shift"}.join("\n")}

          #{function_body}
        }
        END
      else
        str = <<-END.gsub(/^ {8}/, '')
        #{function_name} () {
          #{function_body}
        }
        END
      end
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
      if false_block
        str = <<-END.gsub(/^ {8}/, '')
        if #{condition}; then
          #{true_block}
        else
          #{false_block}
        fi
        END
      else
        str = <<-END.gsub(/^ {8}/, '')
        if #{condition}; then
          #{true_block}
        fi
        END
      end
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

    def self.append(list_name, item)
      "#{list_name}=(\"${#{list_name}[@]}\" #{item})"
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
      return expression.to_bash if expression.is_a?(BashLiteral)
      return Util::quote_string(expression) if expression.is_a?(String)
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
            Util::dashes_to_underscore(expression[1])
          )
        )
        StdLib::dollar(variable)
      when :eval
        expr = expression_to_bash(expression[1])
        StdLib::eval(expr)
      when :defn
        function_name = Util::dashes_to_underscore(expression[1])
        function_args = expression[2]
        function_body = expression_to_bash(expression[3])
        expressions = rest(expression)
        expressions.map {|expr| expression_to_bash(expr)}.join("\n")
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
        item = expression_to_bash(expression[2])
        StdLib::append(list_name, item)
      else
        expression.join(' ')
      end
    end

  end
end
