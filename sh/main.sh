#!/bin/bash

##############################
# Usage: ./main.sh NAME ID   #
##############################

DIFF=5
SUBPROCESS_LIMIT=10
COOLDOWN=2
CT=200

# Good job BSD
[ -n "`uname -a | grep Darwin`" ] && shafunc='shasum' || shafunc='sha1sum'

if [ $# -eq 5 ]
then
	# Nonce calculating subprocess
	hash=$1
	to=$3
	diff=$4
	diff_str=$5

	nonce=$2
	while [ $nonce -le $to ]
	do
		if [ "$(echo -n $hash$nonce | $shafunc | cut -c -$diff)" = $diff_str ]
		then
			echo "Nonce: $nonce"
			curl -s "https://breach.tw/api/search.php?mode=pow&hash=$hash&nonce=$nonce" | jq .
			kill -5 $PPID
			break
		fi
		nonce=$((nonce + 1))
	done
	exit 0
fi

for i in $(seq 1 $DIFF)
do
	DIFF_STR=${DIFF_STR}a
done

name=$1
id=$2
if [ -z $name ]
then
	echo '輸入你的姓名'
	read name
fi

if [ -z $id ]
then
	echo '請輸入身分證後六碼?'
	read id
fi

hash="$(echo -n $name$id | $shafunc | awk '{print $1}')"
echo "SHA1: $hash"

echo 'Calculating Nonce'
trap 'echo Process Completed; exit 0' SIGTRAP
for i in `seq -f %1.0f 0 $CT 10000000`
do
	until [ `jobs | wc -l | sed 's/ //g'` -lt $SUBPROCESS_LIMIT ]
	do
		sleep "$COOLDOWN"
	done
	$0 $hash $i $(($i + $CT - 1)) $DIFF $DIFF_STR &
done
