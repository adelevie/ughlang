#!/bin/bash

urls=("https://18f.gsa.gov/2015/10/26/micro-purchase-criteria-announcement/" "https://18f.gsa.gov/2015/10/29/welcome-to-betafec/" "https://18f.gsa.gov/2015/10/22/preventing-technical-debt/")
get_type_from_url () {
  local url=$1; shift
  
  pa11y -r json $url | jq .[] | jq .type
}

errors=()
warnings=()
notices=()
function_1 () {
  local url=$1; shift
  
  
  local type=`get_type_from_url $url`
  
  if [ "$type" -eq "notice" ]; then
    notices=("${notices[@]}" $type)
  fi

}

for i in ${urls[@]}; do
  function_1 $i
done
echo ${errors[@]}
echo ${warnings[@]}
echo ${notices[@]}
