### Bash literals

You can call any bash commands by wrapping them in parentheses. The following are just examples. If it works in bash, it works in `ugh`.

#### echo

```lisp
(echo 1)
```

```bash
echo 1
```

#### cat

```lisp
(cat hello.txt)
```

```bash
cat hello.txt
```

```lisp
(cat hello.txt > hello.json)
```

```bash
cat foo.json > bar.json
```

#### ls

```lisp
(ls -a)
```

```bash
ls -a
```

#### git

```lisp
(git commit -m "Initial commit")
```

```bash
git commit -m "Initial commit"
```

### Standard Library

The following functions are built-in and form the building blocks of `ugh`.

#### Variables and functions

##### def

Bind a value to a variable. Note that these are global variables.

```lisp
(def foo "bar")
```

```bash
foo="bar"
```

`ugh` follows the Lisp convention of using dashes in variable names. However, during conversion to Bash, dashes are converted to underscores:

```lisp
(def hello-world "Hello, world.")
```

```bash
hello_world="Hello, world."
```

##### dollar

Aliases Bash's `$` to access the value of a variable.

```lisp
(dollar foo)
```

```bash
$foo
```

##### eval

Aliases Bash's command substitution to evaluate an expression.

```lisp
(eval (cat hello.txt))
```

```bash
`cat hello.txt`
```

You can combine this with `def`:

```lisp
(def hello (eval (cat hello.txt)))
```

```bash
hello=`cat hello.txt`
```

Furthermore, you can then combine this with `dollar`:

```lisp
(def filename "hello.txt")
(def hello (eval (cat (dollar filename))))
```

```bash
filename="hello.txt"
hello=`cat $filename`
```

##### defn

Defines a named function.

Example with no arguments:

```lisp
(defn say-hi ()
  (echo "hi"))
```

```bash
say_hi () {
  echo "hi"
}
```

When arguments are given to `defn`, `ugh` automatically converts Bash's positional parameters to locally-bound named variables:

```lisp
(defn say (n)
  (echo (dollar n)))
```

```bash
say () {
  local n=$1
  echo $n
}
```

##### do

Performs a sequence of expressions, from left to right:

```lisp
(do
  (echo "hello")
  (def foo "bar")
  (echo (dollar foo)))
```

```bash
echo "hello"
foo="bar"
echo $foo
```

##### local

Defines a locally-bound variable. These can only be used inside of functions (and not in the global scope):

```lisp
(defn hello ()
  (do
    (local file (eval (cat hello.txt)
    (echo (dollar file))))))
```

```bash
hello () {
  local file=`cat hello.txt`
  echo $file
}
```

#### Conditionals and `if`

These functions control the flow of the program. They rely on Bash's `true` and `false` primitives.

##### eq

Evaluates the equality between two values:

```lisp
(eq 1 1)
```

```bash
[ "1" -eq "1" ]
```

Example with variables:

```lisp
(eq (dollar number) 1)
```

```bash
[ "$number" = "1" ]
```

##### ne

Evaluates the inequality between two values:

```lisp
(ne (dollar number) 1)
```

```bash
[ "$number" -ne "1" ]
```

##### gt

Evaluates if the first expression is greater than the second expression.

```lisp
(gt (dollar number) 1)
```

```bash
[ "$number" -gt "1" ]
```

##### ge

Evaluates if the first expression is greater than or equal to the second expression.

```lisp
(ge (dollar number) 1)
```

```bash
[ "$number" -ge "1" ]
```

##### lt

Evaluates if the first expression is less than the second expression.

```lisp
(lt (dollar number) 1)
```

```bash
[ "$number" -lt "1" ]
```

##### le

Evaluates if the first expression is less than or equal to the second expression.

```lisp
(le (dollar number) 1)
```

```bash
[ "$number" -le "1" ]
```

##### if

Evaluates an expression if a condition is true:

```lisp
(if (eq 1 1)
  (echo "1 equals 1!"))
```

```bash
if [ "1" = "1" ]; then
    echo "1 equals 1!"
fi
```

Optionally pass a second expression which will be evaluated if the condition is false:

```lisp
(if (eq 1 2)
  (echo "1 equals 2?!")
  (echo "1 does not equal 2!"))
```

```bash
if [ "1" = "1" ]; then
    echo "1 equals 2?!"
else
    echo "1 does not equal 2!"
fi
```

#### Data Structures

##### list

`list`s in `ugh` are just Bash literals:

```lisp
(1 2 3 4 5)
```

```bash
(1 2 3 4 5)
```

##### deflist

However, you bind a list to a value using `deflist`:

```lisp
(deflist my-list (1 2 3 4 5))
```

```bash
declare -a my_list=(1 2 3 4 5)
```

##### set

Sets a `list` value at a given index:

```lisp
(set my-list 1 (dollar foo))
```

```bash
my_list[1]=$foo
```

##### get

Gets a `list` value at a given index:

```lisp
(get my-list 1)
```

```bash
${#my_list[1]}
```

Note that `list` indexes are zero-based.

##### length

Gets the length of a `list`:

```lisp
(length my-list)
```

```bash
${#my-list[@]}
```

##### append

Appends one or many elements to the end of a `list`:

```lisp
(append my-list 6 7 8)
```

```bash
"${my_list[@]}" 6 7 8)
```

##### offset

Extract a number of elements from a `list` staring at a given position:

```lisp
(offset my-list 3 2)
```

```bash
${my_list[@]:3:2}
```

#### Functional Programming

##### lambda

Define and call a fake anonymous function:

```lisp
((lambda (x) (echo (dollar x))), "hello")
```

```bash
ugh_anon_function_1 () {
  local x=$1
  echo $x
}
ugh_anon_function_1 "hello"
```

##### each

Iterate over a `list`:

```lisp
(each (1 2 3 4) (lambda (x)
  (echo (dollar x))))
```

```bash
ugh_anon_function_2 () {
  local x=$1
  echo $x
}
for i in 1 2 3 4; do
  ugh_anon_function_2 $i
done
```
