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

# print options and arguments
echo "Output format: $OUTPUT_FORMAT, Output file: $OUTPUT_FILE, First pom: $FIRST_POM, Second pom: $SECOND_POM"

# get working directories
CURRENT_DIR="$( pwd )"
FIRST_POM_DIR="$( cd "$( dirname "${FIRST_POM}" )" && pwd )"
SECOND_POM_DIR="$( cd "$( dirname "${SECOND_POM}" )" && pwd )"

# create temporary directory
TEMP_DIR="/tmp/maven-dependency-comparator"
mkdir -p "$TEMP_DIR"

# get effective poms
mvn help:effective-pom --non-recursive -f "$FIRST_POM" -Doutput="$TEMP_DIR/first_pom.xml" > /dev/null
mvn help:effective-pom --non-recursive -f "$SECOND_POM" -Doutput="$TEMP_DIR/second_pom.xml" > /dev/null
