#!/bin/bash

###################################################
user_token="abcd1234fkjgndklgndkjhgn"
domin="assdasdsd.dns.navy"
record_name='ipv6'
###################################################
ACCOUNT="abcd%40qq.com"
PASSWD="123456"
COOKIE="/tmp/dyn6.txt"
###################################################
# 打印错误信息
function log_e(){	echo -e "\x1b[30;41merror:\x1b[0m \x1b[31m${*}\x1b[0m" >&2; }
# 打印通知信息
function log_i(){ echo -e "\x1b[30;42minfo:\x1b[0m \x1b[32m${*}\x1b[0m" >&2; }
# 打印警告信息
function log_w(){ echo -e "\x1b[30;43mwarning:\x1b[0m \x1b[33m${*}\x1b[0m" >&2; }

function log_in()
{
local a b
log_i "step 1"
a=$(curl -m 10 --retry 5 -s -c "$COOKIE" -H "Host: dynv6.com" -H "sec-ch-ua: \" Not A;Brand\";v=\"99\", \"Chromium\";v=\"102\"" -H "sec-ch-ua-mobile: ?0" -H "sec-ch-ua-platform: \"Windows\"" -H "upgrade-insecure-requests: 1" -H "user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36" -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9" -H "sec-fetch-site: none" -H "sec-fetch-mode: navigate" -H "sec-fetch-user: ?1" -H "sec-fetch-dest: document" -H "accept-language: zh-CN,zh;q=0.9" --compressed "https://dynv6.com/users/sign_in" | tr -d "\r\n")
if [[ "$?" != "0" ]]
then
	log_e 'faild 11'
	return 11
fi
#echo "$a" >1.htm
auth_token=$(echo "$a" | grep -oP 'authenticity_token[^><]+' | grep -oP '(?<=value=")[^\s"]+') 
csrf_token=$(echo "$a" | grep -oP 'csrf-token[^><\/]+' | grep -oP '(?<=content=")[^\s"]+') 
if [[ -z "$csrf_token" || -z "$auth_token" ]]
then
	log_e "failed 12"
	return 12
fi
log_i "auth-token: $auth_token"
log_i "csrf-token: $csrf_token"
log_i "step 2"
b=$(curl -m 10 --retry 5 -L -s -b "$COOKIE"  -c "$COOKIE" -H "Host: dynv6.com" -H "cache-control: max-age=0" -H "sec-ch-ua: \" Not A;Brand\";v=\"99\", \"Chromium\";v=\"102\"" -H "sec-ch-ua-mobile: ?0" -H "sec-ch-ua-platform: \"Windows\"" -H "upgrade-insecure-requests: 1" -H "origin: https://dynv6.com" -H "content-type: application/x-www-form-urlencoded" -H "user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36" -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9" -H "sec-fetch-site: same-origin" -H "sec-fetch-mode: navigate" -H "sec-fetch-user: ?1" -H "sec-fetch-dest: document" -H "referer: https://dynv6.com/users/sign_in" -H "accept-language: zh-CN,zh;q=0.9" --data-binary "authenticity_token=$auth_token&user%5Bemail%5D=$ACCOUNT&user%5Bpassword%5D=$PASSWD&user%5Bremember_me%5D=0&commit=Sign+in" -L --compressed "https://dynv6.com/users/sign_in" | tr -d "\r\n")
#echo "$b" >2.htm
zones_id=$(echo "$b" | grep -ioP 'zones\/\d+[^<]+'"$domin" |  grep -oP '(?<=zones\/)\d+' | sed 'q')
if [[ -z "$zones_id" ]]
then
	log_e 'faild 13'
	return 13
fi
csrf_token=$(echo "$b" | grep -oP 'csrf-token[^><\/]+' | grep -oP '(?<=content=")[^\s"]+') 
log_i "csrf-token: $csrf_token"
log_i "success"
return 0
}


function get_records()
{
local a b c c1 d
if [[ -z "$zones_id" ]]
then
	log_e 'faild 13'
	return 13
fi
log_i "get x-csrf-token"
a=$(curl -m 10 --retry 5  -s  -H "Host: dynv6.com" -H "sec-ch-ua: \" Not A;Brand\";v=\"99\", \"Chromium\";v=\"102\"" -H "sec-ch-ua-mobile: ?0" -H "sec-ch-ua-platform: \"Windows\"" -H "upgrade-insecure-requests: 1" -H "user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36" -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9" -H "sec-fetch-site: same-origin" -H "sec-fetch-mode: navigate" -H "sec-fetch-user: ?1" -H "sec-fetch-dest: document" -H "referer: https://dynv6.com/zones/$zones_id" -H "accept-language: zh-CN,zh;q=0.9" --compressed "https://dynv6.com/zones/$zones_id/records" -b "$COOKIE" -c "$COOKIE" | tr -d "\r\n")
#echo "$a" >3.htm
csrf_token=$(echo "$a" | grep -oP 'csrf-token[^<>\/]+' | grep -oP '(?<=")[^\s"]+')
if [[ -z "$csrf_token" ]]
then
	log_e "failed 21"
	return 21
fi
log_i "csrf-token: $csrf_token"

log_i "get auth-token"
b=$(curl -m 10 --retry 5 -s -H "Host: dynv6.com" -H "sec-ch-ua: \" Not A;Brand\";v=\"99\", \"Chromium\";v=\"102\"" -H "accept: application/json, text/plain, */*" -H "x-csrf-token: $csrf_token" -H "sec-ch-ua-mobile: ?0" -H "user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36" -H "sec-ch-ua-platform: \"Windows\"" -H "origin: https://dynv6.com" -H "sec-fetch-site: same-origin" -H "sec-fetch-mode: cors" -H "sec-fetch-dest: empty" -H "referer: https://dynv6.com/zones/$zones_id/records" -H "accept-language: zh-CN,zh;q=0.9" --data-binary "" --compressed "https://dynv6.com/keys/jwt/refresh" -b "$COOKIE" -c "$COOKIE")
#echo "$b" >4.htm
if [[ -z "$b" ]] || echo $b | grep -iP 'html' >/dev/null
then
	log_e 'failed 22'
	return 22
fi
auth_token="$b"
log_i "auth-token: $auth_token"

log_i "get records"
c=$(curl -m 10 --retry 5 -s -H "Host: dynv6.com" -H "sec-ch-ua: \" Not A;Brand\";v=\"99\", \"Chromium\";v=\"102\"" -H "accept: application/json, text/plain, */*" -H "x-csrf-token: $csrf_token" -H "sec-ch-ua-mobile: ?0" -H "authorization: Bearer $auth_token" -H "user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36" -H "sec-ch-ua-platform: \"Windows\"" -H "sec-fetch-site: same-origin" -H "sec-fetch-mode: cors" -H "sec-fetch-dest: empty" -H "referer: https://dynv6.com/zones/$zones_id/records" -H "accept-language: zh-CN,zh;q=0.9" --compressed "https://dynv6.com/api/v2/zones/$zones_id/records" -b "$COOKIE")
#echo "$c" >5.htm
if [[ -z "$c" ]]
then
	log_e "failed 23"
	return 23
fi

c1=$(echo "$c" |  jq -c '.[]|select(.name=="'"$record_name"'")')
if [[ -z "$c1" ]]
then
	log_e "no such record (\"$record_name\") found."
	return 24
fi
if echo "$c1" | grep -i "$record_ip" >/dev/null
then
	log_w "ip is already up to date"
	return 0
fi
record_id=$(echo "$c1" | jq -c '.id')
if [[ -z "$record_id" ]]
then
	log_e "failed to get record id."
	return 25
fi
log_i "record id: $record_id"
log_i "modify records"
d=$(curl -m 10 --retry 5 -s -X 'PATCH' -H 'authority: dynv6.com' -H 'accept: application/json, text/plain, */*' -H 'accept-language: zh-CN,zh;q=0.9,en;q=0.8' -H "authorization: Bearer $auth_token" -H 'content-type: application/json' -H 'dnt: 1' -H 'origin: https://dynv6.com' -H "referer: https://dynv6.com/zones/$zones_id/records" -H 'sec-ch-ua: " Not A;Brand";v="99", "Chromium";v="102"' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' -H 'sec-fetch-dest: empty' -H 'sec-fetch-mode: cors' -H 'sec-fetch-site: same-origin' -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36' -H "x-csrf-token: $csrf_token" --data-raw "{\"name\":\"${record_name}\",\"data\":\"${record_ip}\"}" --compressed "https://dynv6.com/api/v2/zones/$zones_id/records/$record_id" -b "$COOKIE")
#echo "$d" >6.htm
if echo "$d" | grep -i "$record_ip" >/dev/null
then
	log_i "success"
else
	log_e "failed"
	return 26
fi
return 0
}

function log_out()
{
local a
a=$(curl -m 10 --retry 5 -s -b "$COOKIE" -H 'authority: dynv6.com' -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' -H 'accept-language: zh-CN,zh;q=0.9' -H 'cache-control: max-age=0' -H 'content-type: application/x-www-form-urlencoded' -H 'origin: https://dynv6.com' -H 'referer: https://dynv6.com/zones' -H 'sec-ch-ua: " Not A;Brand";v="99", "Chromium";v="102"' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' -H 'sec-fetch-dest: document' -H 'sec-fetch-mode: navigate' -H 'sec-fetch-site: same-origin' -H 'sec-fetch-user: ?1' -H 'upgrade-insecure-requests: 1' -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36' --data-raw "_method=delete&authenticity_token=$csrf_token" --compressed 'https://dynv6.com/users/sign_out')
#echo "$a" >7.htm
if echo "$a" | grep -iP 'redirected' >/dev/null
then
	log_i "logout: success."
else
	log_e 'logout: failed'
fi
return 0
}

function update_record()
{
local t
if ! touch "$COOKIE"
then
	log_e "failed to make a cookie file."
	return 1
fi
log_in
t=$?
if [[ "$t" = "0" ]]
then 
	get_records
	t=$?
fi
log_out
rm -f "$COOKIE"
return $t
}
######################################################
ipv6p=$(ip -6 addr list scope global | grep -v " fd" | sed -n 's/.*inet6 \([0-9a-f:]\+\/[0-9]\+\).*/\1/p' | head -n 1)
record_ip=$(echo "$ipv6p" | grep -oP '^[\da-fA-F:]+')
log_i "ipv6p: $ipv6p"
log_i "record_ip: $record_ip"

if [[ -z "$record_ip" ]]
then
	log_e "no valid ipv6 addr"
	logger -t "❌dynv6" "没有IPv6地址"
	exit 1
fi

curl -s --retry-all-errors --retry 5 --fail "http://dynv6.com/api/update?ipv6=$record_ip&hostname=$domin&token=$user_token" &>/dev/null
a=$(curl -s --retry-all-errors --retry 5 --fail "http://dynv6.com/api/update?ipv6prefix=$record_ip&hostname=$domin&token=$user_token")

b=$?
if [[ "$b" = "0" ]]
then
	logger -t "✔️dynv6" "IPv6更新成功($a)"
else
	logger -t "❌dynv6" "IPv6更新失败($a)" 
fi

if echo "$a" | grep -i 'updated' &>/dev/null
then
	update_record
	b=$?
	if [[ "$b" = "0" ]]
	then
		logger -t "✔️dynv6" "IPv6 AAAA记录更新成功"
	else
		logger -t "❌dynv6" "IPv6 AAAA记录更新失败, code $b"
	fi
fi

exit 0
