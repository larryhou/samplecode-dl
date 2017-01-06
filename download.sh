#!/bin/bash
# download all apple samplecodes completely
# set -x
JSON='library.json'
export HOME='https://developer.apple.com/library/content'
curl -s ${HOME}/navigation/library.json \
	| tr -d '\040\011\012\015' \
	| sed 's/,}/}/g' | sed 's/,]/]/g' > ${JSON}

function dojob()
{
	# "date:${1} link:${2}"
	location=${HOME}/$(echo ${2} | sed 's/..\///' | awk -F'/Introduction' '{print $1}')
	dir=$(echo ${1} | awk -F'-' '{print $1}')
	if [ ! -d "${dir}" ]
	then
		mkdir -pv ${dir}
	fi
	link=${location}/$(curl -s ${location}/book.json | jq -r '.sampleCode')
	echo "wget ${link} -O ${dir}/$(echo ${link} | awk -F'/' '{print $NF}')"
}

export -f dojob

data=$(cat ${JSON})
date=$(echo "${data}" | jq -r '.columns.date')
link=$(echo "${data}" | jq -r '.columns.url')
id=$(echo "${data}" | jq -r '.columns.id')

echo "${data}" | jq -r ".documents|map([.[${date}],.[${link}]])|map(select(.[1]|contains(\"samplecode\"))|join(\"|\"))|join(\"\n\")" | sort -r | awk -F'|' '{system("dojob "$1" "$2" ")}'
