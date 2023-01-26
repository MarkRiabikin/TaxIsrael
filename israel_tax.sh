#!/bin/bash

: Salary calculator according to Israeli stepped tax
: use http://calc.synel.co.il/en/bn3_show.asp to compare

usage() {
	echo "USAGE:"
	echo
	echo "$ bash ${0##*/}"
	echo "or"
	echo "$ bash ${0##*/} [${ShortOpts}] value"
	echo
	echo "Salary calculator according to Israeli stepped tax"
	echo
	echo "Arguments:"
	echo
	echo " --help | -h"
	echo " --info | -i"
	echo " --execute | -e [:gross_salary:]"
	echo " --compact | -c"
	echo " --extra-tax-points | -s [:number:]. 3 for Ole Hadash"
    echo " -- [:gross_salary:] (optional)"
}

c_echo() {
	if [[ "$compact" == true ]] ; then
		:
	else
		echo "$@"
	fi
}

declare cmd="cmd"
declare int="interact"
declare compact=false

function parseArgs() {
	
	ShortOpts="hie:cs:"
	LongOpts="help,info,exec:,compact,extra-tax-points:"
	
	inputOptions=$(getopt -o "${ShortOpts}" --long "${LongOpts}" --name "${ScriptName}" -- "${@}")
	if [[ "$?" -ne 0 ]]; then
		usage
		exit "$E_OPTERR"
	fi
	
	while [[ "$#" -ne 0 ]]
	do
		case $1 in
		-h | --help )
			usage
			exit 0
		;;
		-i | --info )
			print_taxes_lvls
			exit 0
		;;
		-e | --exec )
			mode="${cmd}"
			cmdsalary="$2"
			shift
			# echo "mode $mode salary $cmdsalary"
		;;
		-c | --compact )
			compact=true
		;;
		-s | --extra-tax-points ) 
			taxpoints="$2"
			if [[ "$taxpoints" =~ ^[0-9]+$ ]] ; then
				:
			else
				echo "extra-tax-points must be a number"
				exit 1
			fi
			shift
		;;
		--) 
			shift
			break
		;;
		*) break
		;;
		esac
		
		shift
	done
	
	shift $(($OPTIND - 1)) # Move argument pointer to next.
	
	if [[ "$#" -eq 0 ]] && [[ "$mode" -eq "$int" ]] ; then
		c_echo "Start interactive mode"
		c_echo
	elif [[ "$#" -eq 1 ]] ; then
		mode="$cmd"
		cmdsalary="$1"
		c_echo "Count NET for salary $1"
		c_echo
	else
		echo "Too many arguments"
		usage
		exit 0
	fi
}

function byebye () {
	c_echo " Bye bye! Hope you will be promoted soon!" 
	exit 0
}

function get_tax_array_ordered() {
	local array=("$@")
	IFS=$'\n'
	array=($(sort -n <<<"${array[*]}"))
	unset IFS
	echo "${array[@]}"
}

function print_taxes_lvls() {
	local lvls=$(get_tax_array_ordered "${!taxarray[@]}")
	echo "=== stepped taxes ==="
	
	# shellcheck disable=SC2068
	for row in ${lvls[@]} ; do
		printf "from %6s tax is %s\n" "$row" "${taxarray[$row]}%" 
	done
	printf "\n"
}

function add_tax() {
	local tax_lvl="$1"
	local tax="$2"
	local msalary="$3"
	tax_to_add=$( echo "scale=2;($msalary - $tax_lvl) * $tax" | bc -l)
	echo "$tax_to_add"
}

function get_taxtotal() {
	local tmpsalary="$1"
	shift
	local mlvls=("$@")
	local taxtotal=0
	
	IFS=$'\n'
	mlvls=($(sort -rn <<<"${mlvls[*]}")) # TODO improve algorythm and remove
	unset IFS

	# shellcheck disable=SC2068
	for lvl in ${mlvls[@]} ; do
		tax_lvl="$lvl"
		if [[ "$tmpsalary" -gt "$tax_lvl" ]] ; then
			tax="${taxarray[$tax_lvl]}"
			tax_to_add=$(add_tax "$tax_lvl" "$tax" "$tmpsalary") 
			# c_echo "taxlvl = $tax_lvl, tax = $tax, tmpsalary = $tmpsalary"
			# c_echo "tax to add: $tax_to_add"
			tmpsalary="$tax_lvl"
			taxtotal=$( echo "$taxtotal + $tax_to_add" | bc -l )
		fi
	done
	
	echo "$taxtotal"
}

function add_tax_points() {
	local NET="$1"
	NET=$( echo "$NET + $taxpoints * $tax1" | bc -l )
	echo "$NET"
}

function get_pre_result() {
	local msalary="$1"
	local taxtotal="$2"
	local NET=$( echo "$msalary - $taxtotal" | bc -l )
	NET=$(add_tax_points "$NET")
	c_echo "======== result: $taxtotal taxes. NET: $NET NIS"
	c_echo
}

function get_final_result() {
	local msalary="$1"
	local taxtotal="$2"
	c_echo "Wait! Withdraw personal and National insurances"
	c_echo ". . ."
	local NET=0
	if [[ "$msalary" -lt 50000 ]] ; then
		NET=$( echo "$msalary - $taxtotal - $msalary * 0.10" | bc -l )
	else
		NET=$( echo "$msalary - $taxtotal - 5000" | bc -l )
	fi
	NET=$(add_tax_points "$NET")
	echo "Only $NET NIS left :("
	echo
	echo "RESULT: $NET NIS"
	printf "\n\n"
}

function main() {
	local loopvar=1
	
	while [ $loopvar -ne 0 ] ; do
		local salary=0
		
		if [[ "$mode" == "$int" ]] ; then
			echo "Enter GROSS salary:"
			read salary
		else
			salary="$cmdsalary"
		fi
		
		if [[ "$salary" =~ ^[0-9]+$ ]] ; then
			c_echo "Counting NET salary for $salary NIS"
		else
			echo "Please, enter a number more than 0"
			echo "your value: $salary"
			[[ "$mode" == "$cmd" ]] &&  exit 1
			continue
		fi
		
		local lvls=$(get_tax_array_ordered "${!taxarray[@]}")
		
		# shellcheck disable=SC2068
		local taxtotal=$(get_taxtotal "$salary" ${lvls[@]})
		
		get_pre_result "$salary" "$taxtotal"
		
		get_final_result "$salary" "$taxtotal"
		
		[[ "$mode" == "$cmd" ]] && exit 0
		
		echo "again? (press 'Enter' or tap 'esc' to exit)"
		read -n 1 exitvar
		case "$exitvar" in 
			$'\e') loopvar=0 ;;
			*) ;;
		esac
	done
}

############################# main #############################

trap "byebye" TERM INT

declare -A taxarray
	taxarray[0]=0.1
	taxarray[6790]=0.14
	taxarray[9730]=0.20
	taxarray[15620]=0.31
	taxarray[21710]=0.35
	taxarray[45180]=0.47
	taxarray[58190]=0.50

tax1=210
taxpoints=0

mode="$int" # default

parseArgs "$@"
main
