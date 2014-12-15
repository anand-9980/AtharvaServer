#!/bin/bash 
#*************************************************************************************************************************
#Created Date : 2014-11-14
#Created By : ATHARVA AUTOMATED PROCESS
#************************************************************************************************************************* 
 

#-- Script related variables
#-- Job Specific variables :ENDS
job_id= 
job_name="Post_Main" 
cd_command="cd /home/user/aanand1/expStrace" 
starting_script="post_main.sh" 
run_command="cd /home/user/aanand1/expStrace; bash post_main.sh" 
#-- Job Specific variables :ENDS
scriptName=`basename $0`
pid_for_job=""
rc=0
ovarall_execution="success"
failure_message=""
#-- Load properties
. ../CONF_ATHARVA_AGENT.properties
. ../Common_function.sh

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
	sqlite_query "$databaseName" "UPDATE $tblRunTransaction SET pid=$pid_for_job, logTraceFile='$unique_stace_op_Location' WHERE run_id=$run_id ;"
	if [[ $? -ne 0 ]]; then
                ovarall_execution="fail"
                failure_message="Failed while inserting into table-$tblRunTransaction of JOB, Job_name=$job_name"
        fi
	#-- Insert into running pool
	sqlite_query "$databaseName" "INSERT INTO $tblCurrentRunningJob VALUES ( $run_id,$job_id,'$job_name',$pid_for_job,'$curr_date','','$STAT_INPROG','','$unique_stace_op_Location');"
	if [[ $? -ne 0 ]]; then
                ovarall_execution="fail"
                failure_message="Failed while inserting into table-$tblCurrentRunningJob, Job_name=$job_name"
        fi
	echo "Exiting from function"
}

#-- Main script starts from here
#-- Check if script has cd command before actually running
if [ -z "$cd_command" ]; then
	echo "No CD command found"
	else 
		echo "==>INFO: CD command found, executing"
		cd $cd_command
		rc=$?
                if [[ $rc -eq 0 ]]; then
                        echo -e "==>INFO-- Successfully executed CD Command for job-$job_name cd_location-$cd_command"
                else
                        echo "==>ERROR-- Error while executing command for job-$job_name cd_location-$cd_command"
                        exit $rc
                fi
fi

#-- Get the runID
#curr_date=$(date +"%m-%d-%Y %T")
curr_date=$(date +"%Y-%m-%d %T")
sqlite_query "$databaseName" "INSERT INTO $tblRunTransaction VALUES ( NULL,$job_id,'$job_name','','$curr_date','','$STAT_INPROG','','');"
rc=$?
if [[ $rc -ne 0 ]]; then
	ovarall_execution="fail"
	failure_message="Failed while inserting into table-$tblRunTransaction, Job_name=$job_name, Exiting without executing job"
	exit $rc
fi
run_id=`sqlite_query "$databaseName" " SELECT max(run_id) from $tblRunTransaction WHERE job_id=$job_id ;"`
echo "==>INFO: Run ID - $run_id for job_name-$job_name"
unique_stace_op_Location="$trace_logs_location/${run_id}_${job_name}.txt"
echo "Unique strace op location - $unique_stace_op_Location, will hit the strace now"

#-- Start the command NOTE: - _exit captures the child exit signal while exit_group process id signal + child process
#sudo strace -s 2000 -t -o $unique_stace_op_Location -e trace=clone,execve,_exit -f $run_command & 
sudo strace -s 2000 -t -o $unique_stace_op_Location -e trace=clone,execve,exit_group -f $run_command &
#-- Trace PID and insert the running pool
getPid &

wait

#-- Update table runTransactions
if [[ $ovarall_execution == "fail" ]]; then
	echo "==> This script-$scriptName execution failed some were"
	#curr_date=$(date +"%m-%d-%Y %T")
	curr_date=$(date +"%Y-%m-%d %T")
	sqlite_query "$databaseName" "UPDATE $tblRunTransaction SET status='$STAT_COMP_FAIL', end_time='$curr_date', message='FAIL-$failure_message' WHERE run_id=$run_id;"
	sqlite_query "$databaseName" "UPDATE $tblCurrentRunningJob SET status='$STAT_COMP_FAIL', end_time='$curr_date', message='FAIL-$failure_message' WHERE run_id=$run_id;"
	#sqlite_query "$databaseName" "DELETE FROM $tblCurrentRunningJob WHERE run_id=$run_id ;"
	if [[ $rc -ne 0 ]]; then
		echo "==>Error: Failed to delete table $tblCurrentRunningJob, exiting"
		exit $rc
        fi
	else
		echo "==> This script-$scriptName execution success"
		#curr_date=$(date +"%m-%d-%Y %T")
		curr_date=$(date +"%Y-%m-%d %T")
        	sqlite_query "$databaseName" "UPDATE $tblRunTransaction SET status='$STAT_COMP', end_time='$curr_date', message='NA' WHERE run_id=$run_id ;"
		sqlite_query "$databaseName" "UPDATE $tblCurrentRunningJob SET status='$STAT_COMP', end_time='$curr_date', message='NA' WHERE run_id=$run_id ;"
        	#sqlite_query "$databaseName" "DELETE FROM $tblCurrentRunningJob WHERE run_id=$run_id ;"
		rc=$?
                if [[ $rc -ne 0 ]]; then
			echo "==>Error: Failed to delete table $tblCurrentRunningJob, exiting"
			exit $rc
		fi
fi 

echo "==>INFO: SUCCESS!! atharva_script=$scriptName, job_name=$job_name, job_id=$job_id, pid-$pid_for_job, strace_op=$unique_stace_op_Location"
