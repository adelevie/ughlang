#!/bin/bash

urls=("https://18f.gsa.gov/2015/10/26/micro-purchase-criteria-announcement/" "https://18f.gsa.gov/2015/10/29/welcome-to-betafec/" "https://18f.gsa.gov/2015/10/22/preventing-technical-debt/")
anon_function_BOAEJDZWHDTHQCHWTXNS () {
  local x=$1; shift
  
  
  echo "Getting a11y error messages for url: "$x
  pa11y -r json $x | jq .[] | jq .message

}

for i in ${urls[@]}; do
  anon_function_BOAEJDZWHDTHQCHWTXNS $i
done
foo=anon_function_APEUOKUYDJMUUJQBTTKI () {
  local x=$1; shift
  local y=$1; shift
  local z=$1; shift
  
  
  echo "hello"
  echo "goodbye"

}
say_hello () {
  
  echo "hello"
}

say_message () {
  local message=$1; shift
  
  echo $message
}

