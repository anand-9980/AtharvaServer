#!/bin/bash
#*************************************************************************************************************************
#Purpose : This script behaves like post man, it sends a list of active jobs and strace op
#Created Date : 4 Nov  2014
#Created By : SHI - Abhishek
#
#*************************************************************************************************************************/
#-- Script related variables
scriptName=`basename $0`
pid_for_job="UNKNOWN"

#-- Load properties
. ./CONF_ATHARVA_AGENT.properties
. ./Common_function.sh

#-- Diplay the PID just incase if this needs to be killed
pid_for_job=`ps -eaf | grep "$scriptName" | egrep -v 'grep|strace' | awk 'BEGIN{ RS="\t" } {print $2}'`
echo "This script- $scriptName will run for ever, to kill use command - kill -9 $pid_for_job"

stracePoolTable="$tblCurrentRunningJob"
#queueNameForStrace="strace_logs"
queueNameForStrace="atharva_proc_msgs"
#-- This has to be run as first script so before running clean up running pool
sqlite_query "$databaseName" "DELETE FROM $stracePoolTable WHERE status='$STAT_COMP' ;"
#-- Infinite loop 
while true
do
	echo -e "\n==> Running script $scriptName again, will run for ever, to kill use command - kill -9 $pid_for_job"
	#-- Check if there is any active job in pool
	all_active_jobs=`sqlite_query "$databaseName" "SELECT run_id FROM $stracePoolTable ;"`	
	if [[ -z $all_active_jobs ]]; then
        	echo "==>INFO: No new job found in active pool"
        else
		#-- Start Posting
		#-- Start Posting running jobs
		echo -e "Start sending job info, java \n"
		java -cp all_running_job_activemq.jar com.shi.JobInfoSender "$stracePoolTable"
		if [[ $? -ne 0 ]]; then
			echo "Falied to run java- for all running job"
			exit 1
		fi
		#-- Start Posting strace
		java -cp strace_pool_sender_activemq.jar com.shi.LiveStarcePoolSender "$stracePoolTable" "$queueNameForStrace"		
		if [[ $? -ne 0 ]]; then
                        echo "Falied to run java- for strace output"
			exit 1
                fi
		
		#-- Call log recycler
		#-- Delete from pool whose status is complete
		wait
		#-- Check if the time when the job started has exeeded 3 mins than delete
		#-- Get all completed rows
		comp_rows_id=`sqlite_query "$databaseName" "SELECT run_id FROM $stracePoolTable  WHERE status='$STAT_COMP';"`
		for run_id in $comp_rows_id; do
			curr_date=$(date +"%Y-%m-%d %T")
			job_comp_time=`sqlite3 DB_ATHARVA.db "select end_time from $stracePoolTable where run_id='$run_id' ;"`
			t1=`date --date="$job_comp_time" +%s`
			t2=`date --date="$curr_date" +%s`
			diff=$((t2-t1))
			sec=60
			minDiff=$((diff / $sec))
			if [[ $minDiff -gt 3 ]]; then
				echo "==> Deleting from current pool now table name- $stracePoolTable for run_id - $run_id since diff from curr_time is mor than 3 mins"
				sqlite_query "$databaseName" "DELETE FROM $stracePoolTable WHERE run_id='$run_id' AND status='$STAT_COMP' ;"			
				if [[ $? -ne 0 ]]; then
				echo "Unable to clean Strace running pool table-$stracePoolTable"
				exit 1
				fi
			else
				echo "==> Not Deleting from current pool now table name- $stracePoolTable for run_id - $run_id as diff from curr_time is less than 3 mins"
			fi
		done
		
	fi
	#-- Sleep
	echo -e "\n Sleeping in post man now----"
	sleep 30
done
#-- Check if we have any items to be sent
