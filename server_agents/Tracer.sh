#!/bin/bash
#********************************************************************************************************************
# Purpose : To capture/trace running jobs
# Date : 1st November 2014
# Author : SHI - Abhishek
#********************************************************************************************************************

#-- Local scripts

#-- Load properties
. ./CONF_ATHARVA_AGENT.properties
. ./Common_function.sh
#-- Check if input argument is passed
if [ $# -eq 0 ]; then
        exit 0
fi

#-- Start tracing
if [[ $1 == "start_tracing" ]]; then
	if [[ -z $2 ]] || [[ -z $3 ]]; then
		echo "==>DEBUG: Second variable should pid"
		exit 1
	fi
	echo "==>INFO ALL PIDS to be traced are-$2 and run_id-$3"
	echo "==>INFO: Sarting to trace for PIDS- $2"
	sudo strace -s 2000 -t -o $trace_logs -e trace=clone,execve,_exit -f  $2 
	rc=$?
	if [[ $rc -ne 0 ]]; then
		echo "==>ERROR: occured while tracing for PIDS - $2"
		#-- Mark as incomplete and delete from pool
		curr_date=$(date +"%m-%d-%Y %T")
                #-- Update that tracing is complete and remove from pool
                sqlite_query "UPDATE $tblRunTransaction SET status='$STAT_COMP', end_time='$curr_date', message='FAIL';"
                sqlite_query "DELETE FROM $tblCurrentRunningJob WHERE run_id IN ($3);"
		exit $rc
	else
		echo "==>INFO: Successfully traced all passed PIDS"
		curr_date=$(date +"%m-%d-%Y %T")
		#-- Update that tracing is complete and remove from pool
		sqlite_query "UPDATE $tblRunTransaction SET status='$STAT_COMP', end_time='$curr_date', message='SUCCESS';"
		sqlite_query "DELETE FROM $tblCurrentRunningJob WHERE run_id IN ($3);" 	
		echo "==>INFO: Successfully updates the status for tracing in tables - $tblRunTransaction & $tblCurrentRunningJob"
	fi	
	#-- Once completed mark this job as complte and remove from running pool
	
fi
echo "==>INFO: Success, Exiting from tracer, For PIDS-$2"
	
