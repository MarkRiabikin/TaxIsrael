#!/bin/bash -e

# read https://askubuntu.com/questions/338857/automatically-enter-input-in-command-line
# for interactive testing

set -x
source="./israel_tax.sh"

declare -a itestdata

itest1="30000\n\033"
itest2="30000\n\n30000\n\033"

tmpitestdata=( ${!itest*} )

for item in ${tmpitestdata[@]}
do
	itestdata=( "${itestdata}" "$item" )
done

echo "${itestdata[@]}"

for t in ${itestdata}
do
	res=$( printf "$t" | bash "$source")
	rcoode="$?"
	if [[ "$rcode" -ne 0 ]] ; then
		echo "test [$t] failed"
		exit 1
	fi
done
