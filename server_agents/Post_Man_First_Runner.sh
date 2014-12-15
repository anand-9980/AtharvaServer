#!/bin/bash
#*************************************************************************************************************************
#Purpose : This script behaves like post man, it sends job-request info for all FIRST RUN jobs
#Created Date : 14 Nov  2014
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

#-- Infinite loop 
while true
do
	echo -e "\n==> Running script $scriptName again, will run for ever, to kill use command - kill -9 $pid_for_job"
	#-- Check if there is any first run job with TRACE_SUCCESS
	first_run_completed_jobs=`sqlite_query "$databaseName" "SELECT request_id FROM $tblFirstTimeRunTracker WHERE status='$STAT_TRACE_SUCCESS' ;"`	
	echo "==>INFO Checking if any first run job to be sent, query SELECT request_id FROM $tblFirstTimeRunTracker WHERE status='$STAT_TRACE_SUCCESS'"
	if [[ -z $first_run_completed_jobs ]]; then
        	echo "==>INFO: No new job found whose first run is complete is ready to be sent"
        else
	 #-- Start Iterating
	  for request_id in $first_run_completed_jobs; do
		#-- Get all request_info
		request_info=`sqlite_query "$databaseName" "SELECT * FROM $tblFirstTimeRunTracker WHERE request_id='$request_id' ;"`
		#-- Get startce location for this request
		logTraceFile=`sqlite_query "$databaseName" "SELECT logTraceFile FROM $tblFirstTimeRunTracker WHERE request_id='$request_id' ;"`
		#-- Start Posting
		#-- Start Posting Request info
		echo -e "Start sending job info, java \n"
		java -cp ./lib/send_message_to_queue.jar com.shi.MessageSenderActiveMq "$request_info" "$first_run_request_info_queue_name"
		if [[ $? -ne 0 ]]; then
			echo "==>ERROR: Falied to run java- request info for- request_id=$request_id queue=$first_run_request_info_queue_name through  MessageSenderActiveMq"
			sqlite_query "$databaseName" " UPDATE $tblFirstTimeRunTracker SET status='$STAT_SEND_TRACE_FAIL',message='Failed while sending request info' WHERE request_id='$request_id' ;"
			if [[ $? -ne 0 ]]; then
				echo "==>ERROR: Failed to update failure status to table $tblFirstTimeRunTracker for request_id=$request_id"
			else
				echo "==>DEBUG: Successfully update failure status to table $tblFirstTimeRunTracker for request_id=$request_id"
			fi
			continue
		fi
		#-- Start Posting complete strace for FIRST RUN
		echo "==>Will send FIRST RUN Strace logs now for request_id=$request_id"
		java -cp ./lib/first_run_activemq.jar com.shi.FirstRunStarceSender "$logTraceFile" "$first_run_trace_queue_name"		
		if [[ $? -ne 0 ]]; then
                        echo "==>ERROR: Falied to run java- for strace output for FIRST RUN logTraceFile=$logTraceFile, request_id=$request_id"
			sqlite_query "$databaseName" " UPDATE $tblFirstTimeRunTracker SET status='$STAT_SEND_TRACE_FAIL',message='Failed while sending strace log' WHERE request_id='$request_id' ;"
			if [[ $? -ne 0 ]]; then
                                echo "==>ERROR: Failed to update failure status to table $tblFirstTimeRunTracker for request_id=$request_id"
                        else
                                echo "==>DEBUG: Successfully update failure status to table $tblFirstTimeRunTracker for request_id=$request_id"
                        fi
			continue
                fi
		#-- Call log recycler
		wait
		#-- UPdate status "SEND_TRACE_SUCCESS
		echo "==>INFO FIRST RUN INFO & TRACE SENT Updating table, QUERY- UPDATE $tblFirstTimeRunTracker SET status='$STAT_SEND_TRACE_SUCCESS' WHERE request_id=$request_id"
		sqlite_query "$databaseName" " UPDATE $tblFirstTimeRunTracker SET status='$STAT_SEND_TRACE_SUCCESS' WHERE request_id=$request_id"
		if [[ $? -ne 0 ]]; then
			echo "==>ERROR: Failed to update SUCCESS status to table $tblFirstTimeRunTracker for request_id=$request_id"
			#break
		else
			echo "==>INFO: Successfully updated SUCCESS status to table $tblFirstTimeRunTracker for request_id=$request_id"
		fi
	  done
		
	fi
	#-- Sleep
	echo -e "\n Sleeping in post man FIRST_RUN_SENDER now----"
	sleep 30
done
#-- Check if we have any items to be sent
