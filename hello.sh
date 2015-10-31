#!/bin/bash

my_list=(1 2 3 4 5 6)
echo ${my_list[0]}
my_list[0]=11
echo ${#my_list[@]}
eight=8
my_list=("${my_list[@]}" $eight)
echo ${#my_list[@]}
$eight
my_list=("${my_list[@]}" $1)
