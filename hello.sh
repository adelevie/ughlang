#!/bin/bash

urls=(https://18f.gsa.gov/2015/10/26/micro-purchase-criteria-announcement/ https://18f.gsa.gov/2015/10/29/welcome-to-betafec/ https://18f.gsa.gov/2015/10/22/preventing-technical-debt/)
anon_function_VDRQXDEHDFYYSVZPIQOR () {
    local x=$1; shift

  echo $x
pa11y -r json $x | jq .[] | jq .message
}

for i in ${urls[@]}; do
  anon_function_VDRQXDEHDFYYSVZPIQOR $i
done
