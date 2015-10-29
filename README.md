# ughlang

A lisp that compiles to bash. For no good reason.

Turns this:

```lisp
(def directory (backticks (bash pwd)))
(echo (dollar directory))

(def gemfile (backticks (bash cat Gemfile)))
(echo (dollar gemfile))

(echo (str "h" "e" "l" (str "l" "o")))

(function say (x) (echo x))
(invoke say "Alan")

(function say_hi () (echo "hi"))
(invoke say_hi)

(function fill_pdf (key value input output)
  (bash pdfq set key value input output))

(begin (echo 1) (echo 2) (echo (str "y" "o")))

(function do_some_things (x) (begin
  (echo 1)
  (echo 2)
  (echo 3)
  (echo (add 10 12))
))

(invoke do_some_things)
```

into

```bash
directory=`pwd`
echo $directory
gemfile=`cat Gemfile`
echo $gemfile
echo hello
say () {
  x=$1
  echo $x
}

say Alan
say_hi () {

  echo hi
}

say_hi
fill_pdf () {
  key=$1; value=$2; input=$3; output=$4
  pdfq set $key $value $input $output
}

echo 1
echo 2
echo yo
do_some_things () {
  x=$1
  echo 1
echo 2
echo 3
echo $((10 + 12))
}

do_some_things
```
