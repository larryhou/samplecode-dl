#!/bin/bash
# find changed apple samplecodes and download incrementally
# set -x
PREV='.library.json'
JSON='library.json'
mv -fv ${JSON} ${PREV}
export HOME='https://developer.apple.com/library/content'
curl -s ${HOME}/navigation/library.json \
	| tr -d '\040\011\012\015' \
	| sed 's/,}/}/g' | sed 's/,]/]/g' > ${JSON}

function dump-json()
{
	data=$(cat ${1})
	date=$(echo "${data}" | jq -r '.columns.date')
	link=$(echo "${data}" | jq -r '.columns.url')
	id=$(echo "${data}" | jq -r '.columns.id')

	echo "${data}" | jq -r ".documents|map(select(.[${link}]|contains(\"samplecode\"))|[.[${id}],.[${date}]]|join(\" \"))|join(\"\n\")" | sort 
}

dump-json ${JSON} > n.txt
dump-json ${PREV} > o.txt

data=$(cat ${JSON})
date=$(echo "${data}" | jq -r '.columns.date')
link=$(echo "${data}" | jq -r '.columns.url')
id=$(echo "${data}" | jq -r '.columns.id')

function dojob()
{
	# date:${1} link:${2}
	location=${HOME}/$(echo ${2} | sed 's/..\///' | awk -F'/Introduction' '{print $1}')
	dir=$(echo ${1} | awk -F'-' '{print $1}')
	if [ ! -d "${dir}" ]
	then
		mkdir -pv ${dir}
	fi
	url=${location}/$(curl -s ${location}/book.json | jq -r '.sampleCode')
	wget ${url} -O ${dir}/$(echo ${url} | awk -F'/' '{print $NF}')
}

export -f dojob

cat n.txt o.txt | sort | uniq -d | sed '1,2d'> d.txt
cat d.txt n.txt | sort | uniq -u | awk '{print $1}' | while read ref
do
	echo "${data}" | jq -r ".documents|map(select(.[${id}]==\"${ref}\")|[.[${date}],.[${link}]]|join(\"|\"))|join(\"\n\")" | awk -F'|' '{system("dojob "$1" "$2)}'
done

rm -f ?.txt

