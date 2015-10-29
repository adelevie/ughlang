require_relative 'ugh'

interpreter = Ugh::Interpreter.new

result = interpreter.transpile(File.open('hello.ugh').read)

File.write("hello.sh", result)
