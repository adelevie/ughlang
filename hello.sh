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
