foo=bar
echo $foo
echo $((10 + 12))
echo $((10 + $((2 + 6))))
hello () {
  echo hi
}

custom () {
  x=$1
  echo $x
}

hello 
custom wub
