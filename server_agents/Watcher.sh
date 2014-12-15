#!/bin/bash
#*************************************************************************************************************************
#Purpose : Wattcher wathes the job to be traced
#Created Date : 1 Novenmer 2014
#Created By : SHI - Abhishek 
#Version : 1.1
#
#*************************************************************************************************************************/
#-- Loacl variables

#-- Load common proerties
. ./CONF_ATHARVA_AGENT.properties

. ./Common_function.sh

#-- Check the active rule - with trace=Y run_time >= Current_time
#-- TODO: Make a check on run_time >= Current_time & also check the transaction table if job ran for today
all_pids=""
declare -a job_ids
run_ids=""
startTraceing="false"
i=0
all_valid_jobs=`sqlite_query "select job_id, job_name,starting_script,starting_script_loc from $tblJobConf where trace='Y';"`
for job in $all_valid_jobs; do
	job_id=`echo $job | awk '{split($0,a,"|"); print a[1]}'`
	job_name=`echo $job | awk '{split($0,a,"|"); print a[2]}'`
	starting_script=`echo $job | awk '{split($0,a,"|"); print a[3]}'`
	echo "==>INFO: Finding PID for starting_script-$starting_script, job_name-$job_name "
	#-- Check if the job is running 
	pid=`ps -eaf | grep "$starting_script" | grep -v grep | awk 'BEGIN{ RS="\t" } {print $2}'`
	if [[ ! -z $pid ]]; then
		echo "==>INFO: New Running job found -> Job_Name:$job_name, starting_script: $starting_script, pid:$pid"
		all_pids+=" -p $pid "
		#-- Insert into running pool & runTransactions
		curr_date=$(date +"%m-%d-%Y %T")
		sqlite_query "INSERT INTO $tblRunTransaction VALUES ( NULL,$job_id,'$job_name',$pid,'$curr_date','','$STAT_INPROG','','');"
		#-- Insert into current pool
		sqlite_query "INSERT INTO $tblCurrentRunningJob VALUES ( NULL,$job_id,'$job_name',$pid,'$curr_date','','$STAT_INPROG','','');"
		#-- Get the runID
		lastRunId=`sqlite_query "SELECT MAX(run_id) FROM $tblRunTransaction;"`
		bash Tracer.sh "start_tracing"
		i=$((i + 1))
		run_ids+="$lastRunId,"
		startTraceing="true"
	else 
		echo "No active PID found for job_name :$job_name" 
	fi
done
#-- 
if [[ $startTraceing == "true" ]]; then
	echo "==>INFO: Start tracing for PID'S - $all_pids, run_id=$run_ids"
	#-- Remove last character from
	run_ids=${run_ids:: -1} 
	bash Tracer.sh "start_tracing" "$all_pids" "$run_ids"
else
	echo "==>INFO: Nothing to trace" 
fi
echo "==>INFO: All done exiting from watcher"
