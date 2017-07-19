#!/bin/bash

# exit on fail
set -e

# make sure getopt is functional
if getopt --test > /dev/null; then
	:
else
	if [[ $? -ne 4 ]]; then
		echo "'getopt --test' failed, exiting..."
		exit 1
	fi
fi

# define help
print_help() {
cat << EOF

Usage:
 ${0##*/} [options] first_pom second_pom

Compare the dependencies of the two given pom.xml files.

Options:
 -f, --format <format>   write output in given format: simple (default), inline, or markdown
 -o, --output <file>     write output to given file, if no file then write to standard output

 -h, --help              Print this help message and exit
EOF
}

# define options
SHORT_OPTIONS=f:ho:
LONG_OPTIONS=format:,help,output:

# parse options
PARSED_OPTIONS=$(getopt --options $SHORT_OPTIONS --longoptions $LONG_OPTIONS --name "$0" -- "$@")
if [[ $? -ne 0 ]]; then
	# if an error occured, getopt already output an error
	exit 2
fi

# ready options for management
eval set -- "$PARSED_OPTIONS"

# manage options
while true; do
	case "$1" in
		-f|--format)
			OUTPUT_FORMAT="$2"
			shift 2
			;;
		-h|--help)
			print_help
			exit 0
			;;
		-o|--output)
			OUTPUT_FILE="$2"
			shift 2
			;;
		--)
			shift
			break
			;;
		*)
			echo "Programming error"
			exit 3
			;;
	esac
done

# handle non-option arguments
if [[ $# -ne 2 ]]; then
	echo "Require 2 pom.xml files to compare dependencies of"
	exit 4
fi
FIRST_POM="$1"
SECOND_POM="$2"

# manage default values
if [[ -z ${OUTPUT_FORMAT+x} ]]; then # if OUTPUT_FORMAT undefined
	OUTPUT_FORMAT=simple
fi

# check values are valid
case $OUTPUT_FORMAT in
	simple|inline|markdown)
		;;
	*)
		echo "value given for output format is invalid"
		exit 5
		;;
esac
if [[ "$(basename "$FIRST_POM")" != "pom.xml" ]] || [[ "$(basename "$SECOND_POM")" != "pom.xml" ]]; then
	echo "Arguments must be pom.xml files"
	exit 6
fi

# create temporary directory
TEMP_DIR="/tmp/maven-dependency-comparator"
mkdir -p "$TEMP_DIR"

# get effective poms
mvn help:effective-pom --non-recursive -f "$FIRST_POM" -Doutput="$TEMP_DIR/first_effective_pom.xml" > /dev/null
mvn help:effective-pom --non-recursive -f "$SECOND_POM" -Doutput="$TEMP_DIR/second_effective_pom.xml" > /dev/null

# parse dependencies into one line each
for name in first second; do
	cat "$TEMP_DIR/${name}_effective_pom.xml" \
		| sed -n \
			-e '/<dependencyManagement>/,/<\/dependencyManagement>/d' \
			-e '/<exclusions>/,/<\/exclusions>/d' \
			-e '/<dependencies>/,/<\/dependencies>/p' \
		| tr -d '\n\t ' \
		| sed \
			-e 's/<!--[^>]*>//g' \
			-e 's/<dependencies>//g' \
			-e 's/<\/dependencies>//g' \
			-e 's/<scope>[^<]*<\/scope>//g' \
			-e 's/<dependency><groupId>\([^<]*\)<\/groupId><artifactId>\([^<]*\)<\/artifactId><version>\([^<]*\)<\/version><\/dependency>/\1 \2 \3\n/g' \
		> "$TEMP_DIR/${name}_oneline_dependencies.txt"
done

# sort dependencies
for name in first second; do
	sort "$TEMP_DIR/${name}_oneline_dependencies.txt" -o "$TEMP_DIR/${name}_oneline_dependencies_sorted.txt"
done

# format dependencies nicely
case "$OUTPUT_FORMAT" in
	simple)
		for name in first second; do
			printf "<<< %s pom.xml's dependencies >>>\n" "${name^}"
			while IFS=$' ' read -r -a line || [[ -n "$line" ]]; do
				printf "%s %s %s\n" "${line[0]}" "${line[1]}" "${line[2]}"
			done < "$TEMP_DIR/${name}_oneline_dependencies_sorted.txt"
			printf "\n"
		done
		;;
	inline)
		# load oneline dependencies
		IFS=$'\n' FIRST_ONELINE_DEPS=($(cat $TEMP_DIR/first_oneline_dependencies_sorted.txt))
		IFS=$'\n' SECOND_ONELINE_DEPS=($(cat $TEMP_DIR/second_oneline_dependencies_sorted.txt))
		# run through arrays
		FIRST_COUNTER=0
		SECOND_COUNTER=0
		while [[ "${FIRST_COUNTER}" -lt "${#FIRST_ONELINE_DEPS[@]}" ]] && [[ "${SECOND_COUNTER}" -lt "${#SECOND_ONELINE_DEPS[@]}" ]]; do
			# get dependency
			IFS=$' ' read -r -a FIRST_DEP <<< "${FIRST_ONELINE_DEPS[FIRST_COUNTER]}"
			IFS=$' ' read -r -a SECOND_DEP <<< "${SECOND_ONELINE_DEPS[SECOND_COUNTER]}"
			# act based on wether a dependency is missing
			if [[ "${FIRST_DEP[0]}.${FIRST_DEP[1]}" == "${SECOND_DEP[0]}.${SECOND_DEP[1]}" ]]; then
				# if dependencies the same
				printf "%s %s %s %s\n" "${FIRST_DEP[0]}" "${FIRST_DEP[1]}" "${FIRST_DEP[2]}" "${SECOND_DEP[2]}"
				FIRST_COUNTER=$(expr $FIRST_COUNTER + 1)
				SECOND_COUNTER=$(expr $SECOND_COUNTER + 1)
			elif [[ "${FIRST_DEP[0]}.${FIRST_DEP[1]}" < "${SECOND_DEP[0]}.${SECOND_DEP[1]}" ]]; then
				# if second pom.xml missing a dependency
				printf "%s %s %s %s\n" "${FIRST_DEP[0]}" "${FIRST_DEP[1]}" "${FIRST_DEP[2]}" "<none>"
				FIRST_COUNTER=$(expr $FIRST_COUNTER + 1)
			else
				# if first pom.xml missing a dependency
				printf "%s %s %s %s\n" "${SECOND_DEP[0]}" "${SECOND_DEP[1]}" "<none>" "${SECOND_DEP[2]}"
				SECOND_COUNTER=$(expr $SECOND_COUNTER + 1)
			fi
		done
		;;
	markdown)
		# load oneline dependencies
		IFS=$'\n' FIRST_ONELINE_DEPS=($(cat $TEMP_DIR/first_oneline_dependencies_sorted.txt))
		IFS=$'\n' SECOND_ONELINE_DEPS=($(cat $TEMP_DIR/second_oneline_dependencies_sorted.txt))
		# run through arrays
		FIRST_COUNTER=0
		SECOND_COUNTER=0
		printf "| %s | %s | %s | %s |\n" "groupId" "artifactId" "first version" "second version"
		printf "|:---:|:---:|:---:|:---:|\n"
		while [[ "${FIRST_COUNTER}" -lt "${#FIRST_ONELINE_DEPS[@]}" ]] && [[ "${SECOND_COUNTER}" -lt "${#SECOND_ONELINE_DEPS[@]}" ]]; do
			# get dependency
			IFS=$' ' read -r -a FIRST_DEP <<< "${FIRST_ONELINE_DEPS[FIRST_COUNTER]}"
			IFS=$' ' read -r -a SECOND_DEP <<< "${SECOND_ONELINE_DEPS[SECOND_COUNTER]}"
			# act based on wether a dependency is missing
			if [[ "${FIRST_DEP[0]}.${FIRST_DEP[1]}" == "${SECOND_DEP[0]}.${SECOND_DEP[1]}" ]]; then
				# if dependencies the same
				if [[ "${FIRST_DEP[2]}" == "${SECOND_DEP[2]}" ]]; then
					printf "| %s | %s | %s | %s |\n" "${FIRST_DEP[0]}" "${FIRST_DEP[1]}" "${FIRST_DEP[2]}" "${SECOND_DEP[2]}"
				else
					printf "| **%s** | **%s** | **%s** | **%s** |\n" "${FIRST_DEP[0]}" "${FIRST_DEP[1]}" "${FIRST_DEP[2]}" "${SECOND_DEP[2]}"
				fi
				FIRST_COUNTER=$(expr $FIRST_COUNTER + 1)
				SECOND_COUNTER=$(expr $SECOND_COUNTER + 1)
			elif [[ "${FIRST_DEP[0]}.${FIRST_DEP[1]}" < "${SECOND_DEP[0]}.${SECOND_DEP[1]}" ]]; then
				# if second pom.xml missing a dependency
				printf "| %s | %s | %s | %s |\n" "${FIRST_DEP[0]}" "${FIRST_DEP[1]}" "${FIRST_DEP[2]}" "<none>"
				FIRST_COUNTER=$(expr $FIRST_COUNTER + 1)
			else
				# if first pom.xml missing a dependency
				printf "| %s | %s | %s | %s |\n" "${SECOND_DEP[0]}" "${SECOND_DEP[1]}" "<none>" "${SECOND_DEP[2]}"
				SECOND_COUNTER=$(expr $SECOND_COUNTER + 1)
			fi
		done
		;;
	*)
		echo "Programming error"
		exit 7
		;;
esac
