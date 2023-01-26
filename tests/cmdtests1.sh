#!/bin/bash

source="./israel_tax.sh"

declare -A testarray1
testarray1[10000]="7885.40"
testarray1[0]=0
testarray1[5000]="4000"


function extract_res() {
	local targetfile="$1"
	local tmpfile="$targetfile".tmp

	awk '{ if ($1 == "RESULT:") print $2 }' "$targetfile" > "$tmpfile"

	local res=$(grep -E "[0-9]*\.?[0-9]+" "$tmpfile")

	echo "$res"
}

error=0

tmpdir=$(mktemp -p ./tests/ -d testdirXXXXX)

testnum=0
testval=0
# test 0
tf="$tmpdir"/test${testnum}.out
output=$(bash "$source" 0 > "$tf")
[[ "$?" -ne 0 ]] && error=1
res=$(extract_res "$tf")

# echo "DEBUG results: res, exp"
# echo "$res"
# echo "${testarray1[0]}"

if [[ "$res" != "${testarray1[$testval]}" ]] ; then 
	error=1
fi

if [[ "$error" -ne "0" ]] ; then
	echo "error in test $testnum"
	echo "see debug info in $tmpdir"
	exit 1
else
	echo "test$testnum pass"
	[[ "x$tmpdir" != "x" ]] && rm -r ./"$tmpdir"
fi

exit 0
