#!/bin/bash

echo "Hello! This program analyzes WhatsApp chat (after you have exported it as a txt file) and calculates some statistics"

if [ $# -ne 1 ]; then
  echo "Please enter the name of the .txt file as the first argument when invoking this command"
  exit 1
fi

chatFile="$1"

echo "Going to read file $chatFile"

echo "Calculating times of each chat"

# times to contain:
# 11/21/16, 8:48 AM - Yuki
# 11/21/16, 8:57 AM - Ravi

# Filter lines which don't start with a date
times=`cat "$chatFile" | cut -d' ' -f1-5 | egrep "[0-9]{1}/[0-9]{1}/[0-9]{2}|[0-9]{2}/[0-9]{2}/[0-9]{2}|[0-9]{1}/[0-9]{2}/[0-9]{2}|[0-9]{2}/[0-9]{1}/[0-9]{2}" `

numMessages=`echo "$times" | awk '{print $5}' | sort | uniq -c | sort -n`

echo -e "\nTotal number of messages sent by each participant"
echo "$numMessages"

members=`echo "$numMessages" | awk '{print $2}'`
echo -e "\nMembers are:\n$members"

echo -e "\n\nCalculating latency in replying"

declare -A latencies
declare -A numReplies

# Initialize the array for each member
for i in $members; do latencies["$i"]=0; numReplies["$i"]=0; done

#set -x

#Assume last sender is the one who sent the most messages
lastSender=`echo "$times" | head -n 1 | awk '{print $5}'`
lastTime=$(date -d"`echo "$times" | head -n 1 | cut -d' ' -f1-3 | sed "s/,//"`" +%s)

# Read each line
while read -r line; do
  sender=`echo "$line" | awk '{print $5}'` # Who sent this message
  thisTime=$(date -d"`echo "$line" | cut -d' ' -f1-3 | sed "s/,//"`" +%s) # When was it sent (in UNIX epoch)

#  echo "Analyzing $line. Sent by \"$sender\" at $thisTime. Last time is \"$lastTime\""

  # This is likely a reply
  if [ "$lastSender" != "$sender" ]; then
    latency=`expr $thisTime - $lastTime`
#    echo "With latency $latency. Last sender was \"$lastSender\""

    lastTime="$thisTime"
    # Don't count latency when its over 3 hours
    if [[ $latency -lt 70 || $latency -gt 10800 ]]; then
      lastSender="$sender"
      continue;
    fi

#    echo "Adding to latency table"
    senderLatency=${latencies["$sender"]}
    senderNumReplies=${numReplies["$sender"]}
    latencies["$sender"]=`expr $senderLatency + $latency`
    numReplies["$sender"]=`expr $senderNumReplies + 1`

  fi 
  lastSender="$sender"
done <<< "$times"

echo -e "Average latency for each participant in the chat\nName    Total Latency   NumReplies    Average Latency In Replying"
for name in "${!latencies[@]}"; do
  echo -e "$name\t " ${latencies["$name"]} "\t\t" ${numReplies["$name"]} "\t\t" `expr ${latencies["$name"]} / ${numReplies["$name"]}`
done
