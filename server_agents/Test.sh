#!/bin/bash

#-- Just for testing delete later
date1='2014-11-07 22:05:09'
date2=`sqlite3 DB_ATHARVA.db "select end_time from runTransactions where run_id=14;"`

echo "date1- $date1 and date2 - $date2"

curr_date=$(date +"%Y-%m-%d %T")

echo "curr_date=$curr_date"

t1=`date --date="$date1" +%s`
t2=`date --date="$curr_date" +%s`

echo "t1- $t1 and t2-$t2"
#let "tDiff=$t2-$t1"
#let "minDiff=$tDiff/60"
diff=$((t2-t1))
sec=60
minDiff=$((diff / $sec))
echo -e "Final diff betwwen date1-$date2 and curr_date-$curr_date is $minDiff --\n"
if [[ $minDiff -gt 5 ]]; then
	echo "Difference is greater than 5 min"
else
	echo "Difference is less than 5 mins"
fi
echo "Exiting..................." >> del_1.txt
