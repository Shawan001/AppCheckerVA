#!/bin/bash

# The purpose of the script is to monitor therap applications on real time. 
# Application status and response time can be monitored.

if [[ $# = 3 ]] # Parameters validation
then
	if [[ $(echo $1 | grep -E "^(secure|beta|help|demo|alpha0[1-3])\.therap(services|global)\.net$") ]] && [[ $(echo $2 | grep -E "^[0-9]{1,2}$") ]] && [[ $(echo $3 | grep -E "^[0-9]{1,2}$") ]]
	then
		echo "[+] Parameter validation :  OK"
	else
		echo "[-] Parameter validation : Failed"
		echo "[+] Usage : $0<space>url<space>sleeptime<space>max_waiting_time"
		echo "[+] Exiting..."
		exit
	fi
else
	echo "[-] Exactly 3 parameters expected"
	echo "[+] Usage : $0<space>url<space>sleeptime<space>max_connection_waiting_time"
	echo "[+] Exting..."
	exit
fi


site_url=$1
checking_url="https://$site_url/auth/appStatus"
sleeptime=$2 # Interval(in seconds) between checks   
max_time=$3  # Maximum metric for response time

echo "### Application checking started at $(date) ###" >> downtime.log.$site_url

espeak "Application checking is starting now" # The purpose of spd-say is to send a message through speech dispatcher (speakers in general)
notify-send -u low "AppCheckerSPD: $site_url" "Application checking is started on a regular interval of $sleeptime s"

while true
do
	
	site_status=($(curl -s --max-time $max_time -w '\t%{time_total}\t%{remote_ip}\n' $checking_url)) #Getting application status through provided url
	
	#site_ip=$(dig +short secure.therapservices.net)
	#site_ip=${site_status[3]}
	#total_time=${site_status[2]}
	
	if [[ $(echo ${site_status[1]} | grep 'OK') ]] # Checking OK string
	then 
		echo -e "\e[92m[+] Application Status [UP] [$(date)] [${site_status[2]}] [${site_status[3]}]"
		#spd-say "Secure site, up"
		sleep $sleeptime
	
	elif [[ $(echo ${site_status[0]} | grep '^[0-9].*') ]]  # Resolving connection time-out issue. If connection timed out then 1st index of the array will be filled up by provided max-time value 
        then
                echo -e "\e[31m[-] High latency detected on secure site [Time-${site_status[0]}]"
		notify-send -u normal "AppCheckerSPD: $site_url" "High latency detected"
                espeak -a 5 "High latency detected on application site"
                sleep $sleeptime

	else # if application is not OK then the url returns sorry page. It is been just checked if returned eliments are part of the sorry page.
		espeak -a 50 "Be alert, Check application please"
		notify-send -u critical "AppCheckerSPD: $site_url" "Application not found"
		#espeak -a 100 "Be alert, Check application please"
		#sleep 5
		echo  "[-] Down at [$(date)] [IP-${site_status[3]}]" >> downtime.log.$site_url
		while true
		do
			site_status_re=($(curl -s -w '\t%{time_total}\t%{remote_ip}\n' https://$site_url/auth/appStatus)) # Double checking
			
			if [[ $(echo ${site_status_re[0]} | grep -o 'DOCTYPE') ]]
			then
				#echo  "[-]Down at [$(date)] [IP-${site_status[-1]}] [Final_check]" >> downtime.log.$site_url
				echo -e "\e[31m[-] Secure Status [Down] [$(date)] [${site_status[-1]}]"
				espeak -a 150 "Application, down"
				sleep 2
			elif [[ $(echo ${site_status_re[1]} | grep 'OK') ]]
			then
				echo -e "\e[92m[+] Secure Status [UP] [$(date)] [${site_status[2]}] [${site_status[3]}]"
				notify-send -u normal "AppCheckerSPD: $site_url" "Application up"
				espeak -a 200 "Application, up"
				echo "[+] Back up at [$(date)] [IP-${site_status[3]}}]" >> downtime.log.$site_url
				break
			else
				echo -e "\e[31m[-] Secure Status [Down] [$(date)] [-] [Unknown Error]"
				notify-send -u critical "AppCheckerSPD: $site_url" "Application not found"
				espeak -a 150 "Application, not found"
			fi			
		done
	fi
done
