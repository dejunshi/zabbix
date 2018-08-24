#!/bin/bash

#Batch install zabbix
#Basic environment tuning for Linux
#author by djshi2
#ip.list file need have ip user and password

! which expect > /dev/null 2>&1 && echo "Please install expect first!" && exit 1

dirpath=$(cd `dirname $0`;pwd)
dir=`dirname $dirpath`

ip_server="$dir/conf/ip_server.list"
ip_agent="$dir/conf/ip_agent.list"

sip=`cat $dir/conf/zabbix.conf | grep -oP "(?<=server=)[^ ]+"`

server_cmd="$dir/etc/zabbix_server"
agent_cmd="$dir/etc/zabbix_agent"

cat $ip_server | while read ip1 user1 password1
do
  /usr/bin/expect << EOF
  set timeout 5
  spawn scp $server_cmd $user1@$ip1:/tmp/
  expect {
          "yes/no" {send "yes\r";exp_continue}
          "assword" {send "$password1\r"}
          timeout {puts "error: timeout on $ip1";exit 1}
          }
  expect {
          "assword" {puts "error: password is wrong on $ip1";exit 1}
          "%" {puts "copy is running on $ip1"}
          }
  set timeout 3000
  expect {
          "100%" {puts "copy file successfully on $ip1"}
          timeout {puts "error: copy file failed on $ip1";exit 1}
          }
  spawn ssh $user1@$ip1 "bash /tmp/zabbix_server $ip1;rm -rf /tmp/zabbix_server"
  expect {
          "yes/no" {send "yes\r";exp_continue}
          "assword" {send "$password1\r"}
          }
  expect eof
EOF
done

cat $ip_agent | while read ip2 user2 password2
do
  /usr/bin/expect << EOF
  set timeout 5
  spawn scp $agent_cmd $user2@$ip2:/tmp/
  expect {
          "yes/no" {send "yes\r";exp_continue}
          "assword" {send "$password2\r"}
          timeout {puts "error: timeout on $ip2";exit 1}
          }
  expect {
          "assword" {puts "error: password is wrong on $ip2";exit 1}
          "%" {puts "copy is running on $ip2"}
          }
  set timeout 3000
  expect {
          "100%" {puts "copy file successfully on $ip2"}
          timeout {puts "error: copy file failed on $ip2";exit 1}
          }
  spawn ssh $user2@$ip2 "bash /tmp/zabbix_agent $ip2 $sip;rm -rf /tmp/zabbix_agent"
  expect {
          "yes/no" {send "yes\r";exp_continue}
          "assword" {send "$password2\r"}
          }
  expect eof
EOF
done
