#!/bin/bash
#*************************************************************************************************************************
#Created Date : 14 Nov  2014
#Created By : SHI - Abhishek
#Purpose This will run script for the first time
#*************************************************************************************************************************/

#-- Script related variables
scriptName=`basename $0`
ovarall_execution="NA"
failure_message="NA"

#-- Load properties
. ./CONF_ATHARVA_AGENT.properties
. ./Common_function.sh


#-- Used to get PID of running jobs and update into transaction tables
function getPid(){
        echo "==>INFO: Inside function getPid, sleeping"
        #-- Give some chance to strace to evolve by sleeping shortly
        sleep 3
        pid_for_job=`ps -eaf | grep "$run_command" | egrep -v 'grep|strace' | awk 'BEGIN{ RS="\t" } {print $2}'`
        rc=$?
        if [[ $rc -ne 0 ]]; then
                ovarall_execution="fail"
                failure_message="Failed while getting PID of JOB, Job_name=$job_name"
        fi
        echo "==>INFO: Unique PID - $pid_for_job for job_id=$job_id, job_name=$job_name"
        #-- Update runTransactions with pid and strace location
        sqlite_query "$databaseName" "UPDATE $tblFirstTimeRunTracker SET pid=$pid_for_job, logTraceFile='$unique_stace_op_Location' WHERE request_id=$request_id ;"
        if [[ $? -ne 0 ]]; then
                ovarall_execution="fail"
                failure_message="Failed while inserting into table-$tblRunTransaction of JOB, Job_name=$job_name, request_id=$request_id"
        fi
        echo "Exiting from function"
}




#-- Main execution starts from here
if [[ -z $1 ]]; then
	echo "==>DEBUG:-$scriptName- This script will run script for first time,expecting <request_id>"
	exit 1
else
	request_id=$1
	echo "==>INFO: $scriptName - Function-executeFirstRun, executing for request_id=$request_id"
        run_command=`sqlite_query "$databaseName" "SELECT run_command FROM $tblFirstRunJobConf where request_id=$request_id ;"`
        cd_command=`sqlite_query "$databaseName" "SELECT cd_command FROM $tblFirstRunJobConf where request_id=$request_id ;"`
	job_id=`sqlite_query "$databaseName" "SELECT job_id FROM $tblFirstRunJobConf where request_id=$request_id ;"`
        job_name=`sqlite_query "$databaseName" "SELECT job_name FROM $tblFirstRunJobConf where request_id=$request_id ;"`
        job_name="${job_name// /_}"
        starting_script=`sqlite_query "$databaseName" "SELECT starting_script FROM $tblFirstRunJobConf where request_id=$request_id ;"`
        if [[ -z $job_name ]]  || [[ -z $starting_script ]] || [[  -z $run_command ]]; then
                echo "==>ERROR- $scriptName - Funcrion-executeFirstRun, Dont have ample job related information to run script for request_id=$request_id"
                return 11
        else
		echo "==>INFO: $scriptName - Function-executeFirstRun , For request_id=$request_id, Information are- run_command=$run_command, cd_command=$cd_command, job_name=$job_name, starting_script=$starting_script"
	fi
	unique_stace_op_Location="$first_run_trace_log_loc/${request_id}_${job_name}.txt"
	#-- Insert entry for new run
	curr_date=$(date +"%Y-%m-%d %T")
	sqlite_query "$databaseName" "INSERT INTO $tblFirstTimeRunTracker VALUES ( $request_id,$job_id,'$job_name','','$curr_date','','$STAT_INPROG','','$unique_stace_op_Location');"
	rc=$?
	if [[ $rc -ne 0 ]]; then
        	ovarall_execution="fail"
        	failure_message="Failed while inserting into table-$tblFirstTimeRunTracker, Job_name=$job_name, Exiting without executing job"
        	exit $rc
	else
		echo "==>INFO:-$scriptName Successfully inserted $tblFirstTimeRunTracker -> VALUES ( $request_id,$job_id,'$job_name','','$curr_date','','$STAT_INPROG','','$unique_stace_op_Location')"
	fi
	
	#-- Main script starts from here
	#-- Check if script has cd command before actually running
	if [ -z "$cd_command" ]; then
        	echo "No CD command found"
        else
                echo "==>INFO: CD command found, executing"
                $cd_command
                rc=$?
                if [[ $rc -eq 0 ]]; then
                        echo -e "==>INFO-- Successfully executed CD Command for job-$job_name cd_location-$cd_command"
                else
                        echo "==>ERROR-- Error while executing command for job-$job_name cd_location-$cd_command"
                        exit $rc
                fi
	fi
	#-- Hit the job
	sudo strace -s 2000 -t -o $unique_stace_op_Location -e trace=clone,execve,exit_group -f $run_command &
	#-- Trace PID and insert the running pool
	getPid &
	wait

	#-- Update table runTransactions
	if [[ $ovarall_execution == "fail" ]]; then
        	echo "==> This script-$scriptName execution failed some were"
        	#curr_date=$(date +"%m-%d-%Y %T")
        	curr_date=$(date +"%Y-%m-%d %T")
        	sqlite_query "$databaseName" "UPDATE $tblFirstTimeRunTracker SET status='$STAT_TRACE_FAIL', end_time='$curr_date', message='FAIL-$failure_message' WHERE request_id=$request_id;"
        	sqlite_query "$databaseName" "UPDATE $tblFirstRunJobConf SET first_run_comp='Y'  WHERE request_id=$request_id;"
        	#sqlite_query "$databaseName" "DELETE FROM $tblCurrentRunningJob WHERE run_id=$run_id ;"
        	if [[ $rc -ne 0 ]]; then
                	echo "==>Error: Failed to delete table $tblFirstRunJobConf, exiting"
                	exit $rc
        	fi
        	else
                	echo "==> This script-$scriptName execution success"
                	#curr_date=$(date +"%m-%d-%Y %T")
                	curr_date=$(date +"%Y-%m-%d %T")
                	sqlite_query "$databaseName" "UPDATE $tblFirstTimeRunTracker SET status='$STAT_TRACE_SUCCESS', end_time='$curr_date', message='NA' WHERE request_id=$request_id ;"
                	sqlite_query "$databaseName" "UPDATE $tblFirstRunJobConf SET first_run_comp='Y' WHERE request_id=$request_id ;"
                	#sqlite_query "$databaseName" "DELETE FROM $tblCurrentRunningJob WHERE run_id=$run_id ;"
                	rc=$?
                	if [[ $rc -ne 0 ]]; then
                        	echo "==>Error: Failed to delete table $tblFirstRunJobConf, exiting"
                        	exit $rc
                	fi
	fi

	echo "==>INFO: SUCCESS!! atharva_script=$scriptName, job_name=$job_name, job_id=$job_id, pid-$pid_for_job, strace_op=$unique_stace_op_Location"
	exit 0	

fi
